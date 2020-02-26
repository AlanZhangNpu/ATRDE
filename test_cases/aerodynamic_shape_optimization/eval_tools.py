#!/usr/bin/env python 

## \file scipy_tools.py
#  \brief tools for interfacing with scipy
#  \author T. Lukaczyk, F. Palacios
#  \version 6.1.0 "Falcon"
#
# The current SU2 release has been coordinated by the
# SU2 International Developers Society <www.su2devsociety.org>
# with selected contributions from the open-source community.
#
# The main research teams contributing to the current release are:
#  - Prof. Juan J. Alonso's group at Stanford University.
#  - Prof. Piero Colonna's group at Delft University of Technology.
#  - Prof. Nicolas R. Gauger's group at Kaiserslautern University of Technology.
#  - Prof. Alberto Guardone's group at Polytechnic University of Milan.
#  - Prof. Rafael Palacios' group at Imperial College London.
#  - Prof. Vincent Terrapon's group at the University of Liege.
#  - Prof. Edwin van der Weide's group at the University of Twente.
#  - Lab. of New Concepts in Aeronautics at Tech. Institute of Aeronautics.
#
# Copyright 2012-2018, Francisco D. Palacios, Thomas D. Economon,
#                      Tim Albring, and the SU2 contributors.
#
# SU2 is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# SU2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with SU2. If not, see <http://www.gnu.org/licenses/>.

# -------------------------------------------------------------------
#  Imports
# -------------------------------------------------------------------

import sys
from numpy import array, zeros

# -------------------------------------------------------------------
#  Scipy CG
# -------------------------------------------------------------------

def evalx0(project,x0=None,xb=None,its=100,accu=1e-10,grads=True):

    obj_f(x0,project)
    con_cieq(x0,project)

    return 0


 
def obj_f(x,project):
    """ obj = obj_f(x,project)
        
        Objective Function
        SU2 Project interface to scipy.fmin_slsqp
        
        su2:         minimize f(x), list[nobj]
        scipy_slsqp: minimize f(x), float
    """
        
    obj_list = project.obj_f(x)
    obj = 0
    for this_obj in obj_list:
        obj = obj+this_obj
    
    return obj

def obj_df(x,project):
    """ dobj = obj_df(x,project)
        
        Objective Function Gradients
        SU2 Project interface to scipy.fmin_slsqp
        
        su2:         df(x), list[nobj x dim]
        scipy_slsqp: df(x), ndarray[dim]
    """    
    
    dobj_list = project.obj_df(x)
    dobj=[0.0]*len(dobj_list[0])
    
    for this_dobj in dobj_list:
        idv=0
        for this_dv_dobj in this_dobj:
            dobj[idv] = dobj[idv]+this_dv_dobj;
            idv+=1
    dobj = array( dobj )
    
    return dobj

def con_ceq(x,project):
    """ cons = con_ceq(x,project)
        
        Equality Constraint Functions
        SU2 Project interface to scipy.fmin_slsqp
        
        su2:         ceq(x) = 0.0, list[nceq]
        scipy_slsqp: ceq(x) = 0.0, ndarray[nceq]
    """
    
    cons = project.con_ceq(x)
    
    if cons: cons = array(cons)
    else:    cons = zeros([0])
        
    return cons

def con_dceq(x,project):
    """ dcons = con_dceq(x,project)
        
        Equality Constraint Gradients
        SU2 Project interface to scipy.fmin_slsqp
        
        su2:         dceq(x), list[nceq x dim]
        scipy_slsqp: dceq(x), ndarray[nceq x dim]
    """
    
    dcons = project.con_dceq(x)

    dim = project.n_dv
    if dcons: dcons = array(dcons)
    else:     dcons = zeros([0,dim])
    
    return dcons

def con_cieq(x,project):
    """ cons = con_cieq(x,project)
        
        Inequality Constraints
        SU2 Project interface to scipy.fmin_slsqp
        
        su2:         cieq(x) < 0.0, list[ncieq]
        scipy_slsqp: cieq(x) > 0.0, ndarray[ncieq]
    """
    
    cons = project.con_cieq(x)
    
    if cons: cons = array(cons)
    else:    cons = zeros([0])
    
    return -cons
    
def con_dcieq(x,project):
    """ dcons = con_dcieq(x,project)
        
        Inequality Constraint Gradients
        SU2 Project interface to scipy.fmin_slsqp
        
        su2:         dcieq(x), list[ncieq x dim]
        scipy_slsqp: dcieq(x), ndarray[ncieq x dim]
    """
    
    dcons = project.con_dcieq(x)
    
    dim = project.n_dv
    if dcons: dcons = array(dcons)
    else:     dcons = zeros([0,dim])
    
    return -dcons
