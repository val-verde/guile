;;; Continuation-passing style (CPS) intermediate language (IL)

;; Copyright (C) 2013, 2014, 2015 Free Software Foundation, Inc.

;;;; This library is free software; you can redistribute it and/or
;;;; modify it under the terms of the GNU Lesser General Public
;;;; License as published by the Free Software Foundation; either
;;;; version 3 of the License, or (at your option) any later version.
;;;;
;;;; This library is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; Lesser General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU Lesser General Public
;;;; License along with this library; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

;;; Commentary:
;;;
;;; This pass kills dead expressions: code that has no side effects, and
;;; whose value is unused.  It does so by marking all live values, and
;;; then discarding other values as dead.  This happens recursively
;;; through procedures, so it should be possible to elide dead
;;; procedures as well.
;;;
;;; Code:

(define-module (language cps2 dce)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (language cps2)
  #:use-module (language cps2 effects-analysis)
  #:use-module (language cps2 renumber)
  ;; #:use-module (language cps2 types)
  #:use-module (language cps2 utils)
  #:use-module (language cps intmap)
  #:use-module (language cps intset)
  #:export (eliminate-dead-code))

(define (elide-type-checks conts effects)
  "Given CONTS, an intmap of the conts in one local function, remove any
&type-check effect from EFFECTS where we can prove that no assertion
will be raised at run-time."
  #;
  (let ((types (infer-types conts)))
    (define (visit-primcall effects fx label name args)
      (if (primcall-types-check? types label name args)
          (intmap-add! effects label (logand fx (lognot &type-check))
                       (lambda (old new) new))
          effects))
    (persistent-intmap
     (intmap-fold (lambda (label cont effects)
                    (let ((fx (intmap-ref effects label)))
                      (cond
                       ((causes-all-effects? fx) effects)
                       ((causes-effect? fx &type-check)
                        (match cont
                          (($ $kargs _ _ exp)
                           (match exp
                             (($ $continue k src ($ $primcall name args))
                              (visit-primcall effects fx label name args))
                             (($ $continue k src ($ $branch _ ($primcall name args)))
                              (visit-primcall effects fx label name args))
                             (_ effects)))
                          (_ effects)))
                       (else effects))))
                  conts
                  effects)))
  effects)

(define (fold-local-conts proc conts label seed)
  (match (intmap-ref conts label)
    (($ $kfun src meta self tail clause)
     (let lp ((label label) (seed seed))
       (if (<= label tail)
           (lp (1+ label) (proc label (intmap-ref conts label) seed))
           seed)))))

(define (postorder-fold-local-conts2 proc conts label seed0 seed1)
  (match (intmap-ref conts label)
    (($ $kfun src meta self tail clause)
     (let ((start label))
       (let lp ((label tail) (seed0 seed0) (seed1 seed1))
         (if (<= start label)
             (let ((cont (intmap-ref conts label)))
               (call-with-values (lambda () (proc label cont seed0 seed1))
                 (lambda (seed0 seed1)
                   (lp (1- label) seed0 seed1))))
             (values seed0 seed1)))))))

(define (fold-nested-functions proc conts seed)
  "Given the renumbered program CONTS, fold PROC over subsets of
CONTS that correspond to each function in the program."
  (define (visit-fun label seed)
    (call-with-values
        (lambda ()
          (postorder-fold-local-conts2
           (lambda (label cont body nested)
             (values (intmap-add! body label cont)
                     (match cont
                       (($ $kargs names vars ($ $continue k src exp))
                        (match exp
                          (($ $fun kfun)
                           (intset-add! nested kfun))
                          (($ $rec names vars (($ $fun kfun) ...))
                           (fold1 (lambda (kfun nested)
                                    (intset-add! nested kfun))
                                  kfun
                                  nested))
                          (_ nested)))
                       (_ nested))))
           conts label empty-intmap empty-intset))
      (lambda (body nested)
        (intset-fold visit-fun
                     nested
                     (proc (persistent-intmap body) seed)))))
  (visit-fun 0 seed))

(define (compute-known-allocations conts effects)
  "Compute the variables bound in CONTS that have known allocation
sites."
  ;; Compute the set of conts that are called with freshly allocated
  ;; values, and subtract from that set the conts that might be called
  ;; with values with unknown allocation sites.  Then convert that set
  ;; of conts into a set of bound variables.
  (call-with-values
      (lambda ()
        (intmap-fold (lambda (label cont known unknown)
                       ;; Note that we only need to add labels to the
                       ;; known/unknown sets if the labels can bind
                       ;; values.  So there's no need to add tail,
                       ;; clause, branch alternate, or prompt handler
                       ;; labels, as they bind no values.
                       (match cont
                         (($ $kargs _ _ ($ $continue k))
                          (let ((fx (intmap-ref effects label)))
                            (if (and (not (causes-all-effects? fx))
                                     (causes-effect? fx &allocation))
                                (values (intset-add! known k) unknown)
                                (values known (intset-add! unknown k)))))
                         (($ $kreceive arity kargs)
                          (values known (intset-add! unknown kargs)))
                         (($ $kfun src meta self tail clause)
                          (values known unknown))
                         (($ $kclause arity body alt)
                          (values known (intset-add! unknown body)))
                         (($ $ktail)
                          (values known unknown))))
                     conts
                     empty-intset
                     empty-intset))
    (lambda (known unknown)
      (persistent-intset
       (intset-fold (lambda (label vars)
                      (match (intmap-ref conts label)
                        (($ $kargs (_) (var)) (intset-add! vars var))
                        (_ vars)))
                    (intset-subtract (persistent-intset known)
                                     (persistent-intset unknown))
                    empty-intset)))))

(define (compute-live-code conts)
  (let* ((effects (fold-nested-functions elide-type-checks
                                         conts
                                         (compute-effects conts)))
         (known-allocations (compute-known-allocations conts effects)))
    (define (adjoin-var var set)
      (intset-add set var))
    (define (adjoin-vars vars set)
      (match vars
        (() set)
        ((var . vars) (adjoin-vars vars (adjoin-var var set)))))
    (define (var-live? var live-vars)
      (intset-ref live-vars var))
    (define (any-var-live? vars live-vars)
      (match vars
        (() #f)
        ((var . vars)
         (or (var-live? var live-vars)
             (any-var-live? vars live-vars)))))
    (define (cont-defs k)
      (match (intmap-ref conts k)
        (($ $kargs _ vars) vars)
        (_ #f)))

    (define (visit-live-exp label k exp live-exps live-vars)
      (match exp
        ((or ($ $const) ($ $prim))
         (values live-exps live-vars))
        (($ $fun body)
         (visit-fun body live-exps live-vars))
        (($ $rec names vars (($ $fun kfuns) ...))
         (let lp ((vars vars) (kfuns kfuns)
                  (live-exps live-exps) (live-vars live-vars))
           (match (vector vars kfuns)
             (#(() ()) (values live-exps live-vars))
             (#((var . vars) (kfun . kfuns))
              (if (var-live? var live-vars)
                  (call-with-values (lambda ()
                                      (visit-fun kfun live-exps live-vars))
                    (lambda (live-exps live-vars)
                      (lp vars kfuns live-exps live-vars)))
                  (lp vars kfuns live-exps live-vars))))))
        (($ $prompt escape? tag handler)
         (values live-exps (adjoin-var tag live-vars)))
        (($ $call proc args)
         (values live-exps (adjoin-vars args (adjoin-var proc live-vars))))
        (($ $callk k proc args)
         (values live-exps (adjoin-vars args (adjoin-var proc live-vars))))
        (($ $primcall name args)
         (values live-exps (adjoin-vars args live-vars)))
        (($ $branch k ($ $primcall name args))
         (values live-exps (adjoin-vars args live-vars)))
        (($ $branch k ($ $values (arg)))
         (values live-exps (adjoin-var arg live-vars)))
        (($ $values args)
         (values live-exps
                 (match (cont-defs k)
                   (#f (adjoin-vars args live-vars))
                   (defs (fold (lambda (use def live-vars)
                                 (if (var-live? def live-vars)
                                     (adjoin-var use live-vars)
                                     live-vars))
                               live-vars args defs)))))))
            
    (define (visit-exp label k exp live-exps live-vars)
      (cond
       ((intset-ref live-exps label)
        ;; Expression live already.
        (visit-live-exp label k exp live-exps live-vars))
       ((let ((defs (cont-defs k))
              (fx (intmap-ref effects label)))
          (or
           ;; No defs; perhaps continuation is $ktail.
           (not defs)
           ;; We don't remove branches.
           (match exp (($ $branch) #t) (_ #f))
           ;; Do we have a live def?
           (any-var-live? defs live-vars)
           ;; Does this expression cause all effects?  If so, it's
           ;; definitely live.
           (causes-all-effects? fx)
           ;; Does it cause a type check, but we weren't able to prove
           ;; that the types check?
           (causes-effect? fx &type-check)
           ;; We might have a setter.  If the object being assigned to
           ;; is live or was not created by us, then this expression is
           ;; live.  Otherwise the value is still dead.
           (and (causes-effect? fx &write)
                (match exp
                  (($ $primcall
                      (or 'vector-set! 'vector-set!/immediate
                          'set-car! 'set-cdr!
                          'box-set!)
                      (obj . _))
                   (or (var-live? obj live-vars)
                       (not (intset-ref known-allocations obj))))
                  (_ #t)))))
        ;; Mark expression as live and visit.
        (visit-live-exp label k exp (intset-add live-exps label) live-vars))
       (else
        ;; Still dead.
        (values live-exps live-vars))))

    (define (visit-fun label live-exps live-vars)
      ;; Visit uses before definitions.
      (postorder-fold-local-conts2
       (lambda (label cont live-exps live-vars)
         (match cont
           (($ $kargs _ _ ($ $continue k src exp))
            (visit-exp label k exp live-exps live-vars))
           (($ $kreceive arity kargs)
            (values live-exps live-vars))
           (($ $kclause arity kargs kalt)
            (values live-exps (adjoin-vars (cont-defs kargs) live-vars)))
           (($ $kfun src meta self)
            (values live-exps (adjoin-var self live-vars)))
           (($ $ktail)
            (values live-exps live-vars))))
       conts label live-exps live-vars))
       
    (fixpoint (lambda (live-exps live-vars)
                (visit-fun 0 live-exps live-vars))
              empty-intset
              empty-intset)))

(define-syntax adjoin-conts
  (syntax-rules ()
    ((_ (exp ...) clause ...)
     (let ((cps (exp ...)))
       (adjoin-conts cps clause ...)))
    ((_ cps (label cont) clause ...)
     (adjoin-conts (intmap-add! cps label (build-cont cont))
       clause ...))
    ((_ cps)
     cps)))

(define (process-eliminations conts live-exps live-vars)
  (define (exp-live? label)
    (intset-ref live-exps label))
  (define (value-live? var)
    (intset-ref live-vars var))
  (define (make-adaptor k src defs)
    (let* ((names (map (lambda (_) 'tmp) defs))
           (vars (map (lambda (_) (fresh-var)) defs))
           (live (filter-map (lambda (def var)
                               (and (value-live? def) var))
                             defs vars)))
      (build-cont
        ($kargs names vars
          ($continue k src ($values live))))))
  (define (visit-term label term cps)
    (match term
      (($ $continue k src exp)
       (if (exp-live? label)
           (match exp
             (($ $fun body)
              (values (visit-fun body cps)
                      term))
             (($ $rec names vars funs)
              (match (filter-map (lambda (name var fun)
                                   (and (value-live? var)
                                        (list name var fun)))
                                 names vars funs)
                (()
                 (values cps
                         (build-term ($continue k src ($values ())))))
                (((names vars funs) ...)
                 (values (fold1 (lambda (fun cps)
                                  (match fun
                                    (($ $fun kfun)
                                     (visit-fun kfun cps))))
                                funs cps)
                         (build-term ($continue k src
                                       ($rec names vars funs)))))))
             (_
              (match (intmap-ref conts k)
                (($ $kargs ())
                 (values cps term))
                (($ $kargs names ((? value-live?) ...))
                 (values cps term))
                (($ $kargs names vars)
                 (match exp
                   (($ $values args)
                    (let ((args (filter-map (lambda (use def)
                                              (and (value-live? def) use))
                                            args vars)))
                      (values cps
                              (build-term
                                ($continue k src ($values args))))))
                   (_
                    (let-fresh (adapt) ()
                      (values (adjoin-conts cps
                                (adapt ,(make-adaptor k src vars)))
                              (build-term
                                ($continue adapt src ,exp)))))))
                (_
                 (values cps term)))))
           (values cps
                   (build-term
                     ($continue k src ($values ()))))))))
  (define (visit-cont label cont cps)
    (match cont
      (($ $kargs names vars term)
       (match (filter-map (lambda (name var)
                            (and (value-live? var)
                                 (cons name var)))
                          names vars)
         (((names . vars) ...)
          (call-with-values (lambda () (visit-term label term cps))
            (lambda (cps term)
              (adjoin-conts cps
                (label ($kargs names vars ,term))))))))
      (($ $kreceive ($ $arity req () rest () #f) kargs)
       (let ((defs (match (intmap-ref conts kargs)
                     (($ $kargs names vars) vars))))
         (if (and-map value-live? defs)
             (adjoin-conts cps (label ,cont))
             (let-fresh (adapt) ()
               (adjoin-conts cps
                 (adapt ,(make-adaptor kargs #f defs))
                 (label ($kreceive req rest adapt)))))))
      (_
       (adjoin-conts cps (label ,cont)))))
  (define (visit-fun kfun cps)
    (fold-local-conts visit-cont conts kfun cps))
  (with-fresh-name-state conts
    (persistent-intmap (visit-fun 0 empty-intmap))))

(define (eliminate-dead-code conts)
  ;; We work on a renumbered program so that we can easily visit uses
  ;; before definitions just by visiting higher-numbered labels before
  ;; lower-numbered labels.  Renumbering is also a precondition for type
  ;; inference.
  (let ((conts (renumber conts)))
    (call-with-values (lambda () (compute-live-code conts))
      (lambda (live-exps live-vars)
        (process-eliminations conts live-exps live-vars)))))

;;; Local Variables:
;;; eval: (put 'adjoin-conts 'scheme-indent-function 1)
;;; End: