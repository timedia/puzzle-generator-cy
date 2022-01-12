##	NP(Number Place) Solver Module
##
##	This class has the main method.
##
##(c) 2019-2021  FUJIWARA Hirofumi, Knowledge Engineering Center, Time Intermedia, Inc.
## This code is licensed under MIT license (see LICENSE.txt for details)
##

#distutils: language=c++

#cython: language_level=3
##  #cython: profile=True
#cython: boundscheck=False
#cython: wraparound=False

import  parameter
import  numpy as np
import  sys
import  NP

DEF     EXCEPTION_CODE = -99

cdef int    SIZE = parameter.SIZE
cdef int    SUBSIZE = parameter.SUBSIZE

cdef int[:,:]   board
cdef char[:,:,:] candidate


def solve( bd ):

    initialize()

    blanks = setProblem(bd)
    if blanks < 0:
        return -1

    if checkLoop() >= 0:
        return blankCount()

    return -1


cdef initialize():
    global candidate, board

    board = np.zeros((SIZE,SIZE),dtype=np.int32)
    candidate = np.ones((SIZE,SIZE,SIZE+1),dtype=np.int8)


cdef int setProblem( bd ) except? EXCEPTION_CODE:
    cdef int r, c

    for r in range(SIZE):
        for c in range(SIZE):
            if bd[r][c]:
                setValue( r, c, bd[r][c] )
    
    return blankCount()


cdef bint checkLoop() except? EXCEPTION_CODE:
    cdef bint   changed, ret
    cdef int    r, c
    
    changed = True
    while changed:
        changed = False

        for r in range(0,SIZE,SUBSIZE):         # 3x3 Blocok Check
            for c in range(0,SIZE,SUBSIZE):
                ret = checkBlock(c,r)
                if ret == EXCEPTION_CODE:
                    return EXCEPTION_CODE
                if ret:
                    changed = True
        if changed:
            continue

        for r in range(SIZE):            # HLine check
            ret = checkHline(r)
            if ret == EXCEPTION_CODE:
                return EXCEPTION_CODE
            if ret:
                changed = True
        if changed:
            continue
        
        for c in range(SIZE):            # VLine check
            ret = checkVline(c)
            if ret == EXCEPTION_CODE:
                return EXCEPTION_CODE
            if ret:
                changed = True
        if changed:
            continue

        for r in range(SIZE):            # Cell check
            for c in range(SIZE):
                ret = checkCell(c,r)
                if ret == EXCEPTION_CODE:
                    return EXCEPTION_CODE
                if ret:
                    changed = True

        if blankCount() == 0:
            break

    return changed

## --------------------		set value	--------------------

cdef bint setValue( int r, int c, int v ) except? False:
    cdef int i, n, r0, c0

    if not candidate[r][c][v]:
        return EXCEPTION_CODE

    if board[r][c]:
        if board[r][c] != v:
            return EXCEPTION_CODE
        return True

    board[r][c] = v
    for n in range(1,SIZE+1):
        candidate[r][c][n] = False
    
    r0 = (r//SUBSIZE)*SUBSIZE
    c0 = (c//SUBSIZE)*SUBSIZE

    for i in range(SIZE):
        candidate[r][i][v] = False
        candidate[i][c][v] = False
        candidate[r0+(i//SUBSIZE)][c0+i%SUBSIZE][v] = False

    return True

## --------------------		get value	--------------------

def getAnswer():
    ans = np.zeros((SIZE,SIZE)).astype(int)        
    NP.copyBoard( board, ans )
    return ans

def getValue( int r, int c ):
    return board[r][c]

def getCandidate( int r, int c ):
    return candidate[r][c]

## --------------------		print	--------------------

def printCandidate():
    cdef int r, c, n

    print("Solver.candidate:")

    for r in range(SIZE):
        for c in range(SIZE):
            for n in range(1,SIZE+1):
                if candidate[r][c][n]:
                    h = n
                else:
                    h = 0
                if h!=0:
                    print(h,end='')
                else:
                    print('-',end='')
            print(' ',end='')
        print()
        

def printBoard():
    sys.stdeerr.write("Solver.board:\n")
    NP.printBoard(sys.stderr,board)

## --------------------	check box/line/cell & set	--------------------

cdef bint checkBlock( int c0, int r0 ) except? EXCEPTION_CODE:
    cdef:
        int    n, cnt, col, row, r, c, can
        bint   changed, exist
    
    changed = False
    for n in range(1,SIZE+1):
        exist = False
        cnt = 0
        col = 0
        row = 0
        for r in range(r0,r0+SUBSIZE):
            for c in range(c0,c0+SUBSIZE):
                if board[r][c] == n:
                    exist = True
                    break
                if candidate[r][c][n]:
                    cnt += 1
                    col = c
                    row = r
            if exist:
                break
            
        if not exist:
            if cnt == 1:
                if not setValue( row, col, n ):
                    return EXCEPTION_CODE
                changed = True
            elif cnt == 0:
                return EXCEPTION_CODE
            
    return changed


cdef bint checkHline( int r ) except? EXCEPTION_CODE:
    cdef:
        int    n, cnt, col, c
        bint   changed, exist
    
    changed = False
    for n in range(1,SIZE+1):
        exist = False
        cnt = 0
        col = 0
        for c in range(SIZE):
            if board[r][c] == n:
                exist = True
            if candidate[r][c][n]:
                cnt += 1
                col = c

        if not exist:
            if cnt == 1:
                setValue( r, col, n )
                changed = True
            elif cnt == 0:
                return EXCEPTION_CODE
            
    return changed


cdef bint checkVline( int c ) except? EXCEPTION_CODE:
    cdef:
        int    n, cnt, col, r
        bint   changed, exist
    
    changed = False
    for n in range(1,SIZE+1):
        exist = False
        cnt = 0
        row = 0
        for r in range(SIZE):
            if board[r][c] == n:
                exist = True
            if candidate[r][c][n]:
                cnt += 1
                row = r

        if not exist:
            if cnt == 1:
                setValue( row, c, n )
                changed = True
            elif cnt == 0:
                return EXCEPTION_CODE

    return changed


cdef bint checkCell( int c, int r ) except? EXCEPTION_CODE:
    cdef int    n, cnt, v
    
    if board[r][c]:
        return False

    cnt = 0
    v = 0
    for n in range(1,SIZE+1):
        if candidate[r][c][n]:
            cnt += 1
            v = n

    if cnt == 1:
        setValue( r, c, v )
        return True
    elif cnt == 0:
        return EXCEPTION_CODE
    
    return False

## --------------------	blank count	--------------------

cdef int blankCount():
    cdef int cnt, r, c

    cnt = 0
    for r in range(SIZE):
        for c in range(SIZE):
            if not board[r][c]:
                cnt += 1

    return cnt

