#ifndef SCM_DYNL_H
#define SCM_DYNL_H

/* Copyright 1996,1998,2000-2001,2006,2008,2010,2018,2021
     Free Software Foundation, Inc.

   This file is part of Guile.

   Guile is free software: you can redistribute it and/or modify it
   under the terms of the GNU Lesser General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   Guile is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
   License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with Guile.  If not, see
   <https://www.gnu.org/licenses/>.  */



#include "libguile/scm.h"



SCM_API SCM scm_dynamic_link (SCM fname);
SCM_API SCM scm_dynamic_object_p (SCM obj);
SCM_API SCM scm_dynamic_pointer (SCM name, SCM obj);
SCM_API SCM scm_dynamic_func (SCM name, SCM obj);
SCM_API SCM scm_dynamic_call (SCM name, SCM obj);

SCM_INTERNAL void scm_init_dynamic_linking (void);

#endif  /* SCM_DYNL_H */
