C MODPATH-PLOT Version 4.00 (V4, Release 1, 2-2000) [PC]
C  Fixed problem in GPM
C
C  Changes to work with MODFLOW-2000
C
C MODPATH-PLOT Version 3.00 (V3, Release 2, 5-99)
C************************************************************************************
C
C   The following routines originally in GKSINT.FOR were modified by DWP:
C                          ------------------------
C
C   GSWN   -- fixed problem so that now scalar transformations XWMIN, XWMAX,
C             YWMIN, YWMAX, MXWXV, and MYWYV are updated if the call to GSWN
C             is resetting window dimensions for the currently selected
C             transformation number. Before, those scalar variables were
C             only updated by a call to GSELNT. This caused a problem in
C             MODPATH-PLOT because window dimensions are reset several times
C             for transformation number 1 without intermediate calls to
C             GSELNT.
C
C   GSVP   -- fixed problem so that now scalar transformations XVMIN, XVMAX,
C             YVMIN, YVMAX, MXWXV, and MYWYV are updated if the call to GSVP
C             is resetting viewport dimensions for the currently selected
C             transformation number. See above (GSWN) for further explanation.
C
C   GSELNT -- set a new global variable named CURNTN = current transformation
C             number. CURNTN was added to common in LKAGKS.INC.
C
C   GOPKS  -- initialized CURNTN = 0. initialized CHARUX=0.0 & CHARUY=1.0
C
C   GPL    -- added code to do polyline clipping if the clipping indicator is
C             set to yes.
C
C   GPM    -- added crude clipping for polymarkers. if marker point is outside
C             of clipping rectangle it is not plotted.
C
C   GTX    -- added crude clipping for text. if text reference point is outside
C             of clipping rectangle it is not drawn.
C
C   GFA    -- added crude clipping for filled polygons. If polygon is entirely
C             within clipping rectangle, it is drawn and filled. If part of polygon lies outside
C             rectangle, it's outline is drawn and clipped but it is not filled at all. 
C             This is not really a satisfactory solution, but it generally is
C             more acceptable than filling beyond the clipping rectangle. For polygons
C             that are not filled, it is a complete implementation of GKS clipping.
C
C             NOTE: When line hatch fill patterns are selected in Modpath-Plot,
C             Modpath-Plot generates software hatch shading itself with calls to GPL.
C             Consequently, the polyline clipping added in GPL will, in effect,
C             generate clipped polygons that are filled in MODPATH-PLOT if the fill style is a
C             hatch type. Clipped solid-filled polygons are not filled in this
C             implementation of Modpath-Plot. At some point, the hatch fill
C             emulation module from Modpath-Plot (or a modification of it) could
C             be incorporated directly into this GKS to provide emulated clipped
C             hatch-shaded polygons for other programs. That would require a lot of work
C             to make sure it is implemented in a general way.
C
C   GSCR   -- added code to allow the RGB color mix to be changed for color numbers 0-15.
C
C   File LKAGKS.INC -- added scalar variable CURNTN to common. CURNTN = current
C                      normalization transformation number. added arrays CLRRED(0:15),
C                      CLRGRN(0:15), and CLRBLU(0:15) to hold the RGB color values for
C                      the 16 color available PC color numbers.
C
C********************************************************************************
C
C   The following routines originally in GKSINTX.FOR were modified by DWP:
C                          -------------------------
C
C   GQNT   -- was dummy routine. now retrieves window and viewport dimensions
C   GQCNTN -- was dummy routine. now retrieves current transformation number
C   GQWKC  -- was dummy routine. now returns workstation type
C   GQLN   -- was dummy routine. now returns actual line style
C   GQCHUP -- was dummy routine, now returns actual x & y vector components
C   GQTXAL -- was dummy routine, now returns actual x & y text alignment flags
C   GQTXCI -- was dummy routine, now returns actual color index number for text
C   GQCR   -- was dummy routine, now returns current RGB settings for specified 
C             color index.
C
C********************************************************************************
C
C    The following new GKS routines were added to deal with clipping:
C                  ---
C
C    GQCLIP  -- retrieves clipping on/off indicator and the current
C               clipping rectangle
C
C********************************************************************************
C
C    The following computational routines were added to implement polyline
C    clipping and crude text, marker, and polygon fill clipping.
C
C    INRECT   -- determine if a point is within clipping rectangle
C    XYINT    -- find the intersection point of a line segment with
C                the clipping rectangle
C    VSIDE    -- find potential intersection points along vertical
C                sides of the clipping rectangle
C    HSIDE    -- find potential intersection points along horizontal
C                sides of the clipping rectangle
C*********************************************************************************
C
      BLOCK DATA GKSINT
C
C     + + + PURPOSE + + +
C     initialize various values in the common blocks for GKS
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'LKAGKS.INC'
C
C     + + + DATA INITIALIZATIONS + + +
      DATA GKSOPN/0/,WSSTAT/MXNWKS*0.0/
C
      END
C
C
C
      SUBROUTINE   GOPKS
     I                  (ERRFIL, BUFA)
C
C     + + + PURPOSE + + +
C     start working with GKS
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   ERRFIL, BUFA
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRFIL - error message file
C     BUFA   - buffer area memory units, not used
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER      I, J,LCLR(16)
      REAL         R(16), G(16), B(16)
      LOGICAL      OPN
      CHARACTER*64 EXNAME
C
C     + + + DATA INITIALIZATIONS + + +
C     standard aqt/usgs colors (interactor GCOLN)
C*DWP* changed last color number to 152 (was originally 0)
C               black,white,red,  green,blue, cyan, magen,yello,
      DATA LCLR/  0,  216,  40,   104,  168,  136,  200,  56,
     #           72,  248,  184,  232,  24,   88,   120,  152/
C               orang,brown,viole,grey, ltred,ltgrn,ltblu,x

C*DWP* added local arrays R, G, and B to hold initial RGB values
C
      DATA R     /0.00, 1.00, 0.70, 1.00, 1.00, 0.00, 0.00, 0.00,
     #            0.00, 0.00, 0.00, 1.00, 0.70, 1.00, 0.60, 0.30/
      DATA G     /0.00, 0.00, 0.00, 1.00, 0.60, 1.00, 0.70, 1.00,
     #            0.70, 0.00, 0.00, 0.00, 0.00, 1.00, 0.60, 0.30/
      DATA B     /0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1.00,
     #            0.70, 1.00, 0.70, 1.00, 0.70, 1.00, 0.60, 0.30/
C
C     + + + OUTPUT FILES + + +
 2000 FORMAT(/,' GOPKS:Error file unit number',I5,' is already open.',
     #       /,9X,'It will be used for error reporting.',
     #       /,9X,'Its name is:',5X,A)
 2010 FORMAT(/,' GOPKS:Error file unit number',I5,' opened.',
     #       /,9X,'It will be used for error reporting.',
     #       /,9X,'Its name is:',5X,A)
C
C     + + + END SPECIFCATIONS + + +
C
C     clear error and warning flags
      EFLAG = 0
      WFLAG = 0
C
C     transfer errfil to common
      STDERR = ERRFIL
C
      INQUIRE(UNIT=STDERR, OPENED=OPN, NAME=EXNAME)
      IF (OPN) THEN
        WRITE(STDERR,2000) STDERR, EXNAME
      ELSE
        EXNAME= 'error.fil'
        OPEN(UNIT=STDERR, FILE=EXNAME)
        WRITE(STDERR,2010) STDERR, EXNAME
      END IF
C
C     set clipping off- clipping not yet supported, may never be!
      CLIPIT = 0
C
C     set non-standard polymarker option to OFF
      MRKOPT = 0
C
C     set default trarnsformation 0
      XWMINV(0) = 0
      XWMAXV(0) = 1.0
      YWMINV(0) = 0
      YWMAXV(0) = 1.0
      XVMINV(0) = 0
      XVMAXV(0) = 1.0
      YVMINV(0) = 0
      YVMAXV(0) = 1.0
      MXWXVV(0) = 1.0
      MYWYVV(0) = 1.0
C     set current transformation to 0
      XWMIN= XWMINV(0)
      XWMAX= XWMAXV(0)
      YWMIN= YWMINV(0)
      YWMAX= YWMAXV(0)
      XVMIN= XVMINV(0)
      XVMAX= XVMAXV(0)
      YVMIN= YVMINV(0)
      YVMAX= YVMAXV(0)
      MXWXV= MXWXVV(0)
      MYWYV= MYWYVV(0)
C
C     set workstation window and workstation
C     viewport limits to zero.  can be used as flag to indicate lack
C     of some information in later subprograms.
      DO 100 I=1,MXNTNR
        XWMINV(I) = 0.0
        XWMAXV(I) = 0.0
        YWMINV(I) = 0.0
        YWMAXV(I) = 0.0
        XVMINV(I) = 0.0
        XVMAXV(I) = 0.0
        YVMINV(I) = 0.0
        YVMAXV(I) = 0.0
100   CONTINUE
C
      DO 110 I=1,MXNWKS
        XNMINV(I) = 0.0
        XNMAXV(I) = 0.0
        YNMINV(I) = 0.0
        YNMAXV(I) = 0.0
        XDMINV(I) = 0.0
        XDMAXV(I) = 0.0
        YDMINV(I) = 0.0
        YDMAXV(I) = 0.0
110   CONTINUE

C*DWP* added code to set RGB values in arrays clrred, clrgrn, and clrblu
C
C     set standard dos color type, current color table, and
C     initiate RGB values for color table
      DO 130 I=1,MXNWKS
        DO 120 J=0,15
          DOSCLR(I,J) = J
          CLRTAB(I,J) = LCLR(J+1)
          CLRRED(I,J) = R(J+1)
          CLRGRN(I,J) = G(J+1)
          CLRBLU(I,J) = B(J+1)
120     CONTINUE
130   CONTINUE
C
C     a shrunk circle is used for marker 1.  a circle is used
C     for 4 and an hourglass for 3 in place of an asterisk because
C     a centered asterisk symbol is not available
C     set base values for line width and marker height
      BSLINW = 0.015
      BSMRKH = 0.05
C
C     set defualt values for character baseline
      CHARBX = 0.0
      CHARBY = 0.0
C
C     set default character height
      CHARH = 0.10
C
C     set default factors for poly lines
      GLTYPE = FULL
      GLWID  = 1.0
      LCOLOR = BRIGHTWHITE
      PLWID  = BSLINW
C
C     set default factors for polymarkers
      MTYPE = 1
      MARKH = BSMRKH
      MCOLOR= BRIGHTWHITE
      MARKSF= 1.0
C
C     set default values for polyline and polymarker
C     representations: bundled.
      DO 150 I=1,MXNWKS
        DO 140 J=1,MXNPLI
          LTYPE(I,J) = 0
          LWIDTH(I,J)= 1.0
          ARPLCI(I,J)= LIGHTYELLOW
140     CONTINUE
C
        DO 145 J=1,MXNPMI
          ARMT(I,J)  = 1
          ARMS(I,J)  = 1
          ARPMCI(I,J)= LIGHTYELLOW
145     CONTINUE
150   CONTINUE
C
C     set default hatch symbols
C
C     set the default line patterns for interactor
C     solid, dash, dot, mix, 1usr
      LINPTR(1)= 0
      LINPTR(2)= 2
      LINPTR(3)= 1
      LINPTR(4)= 3
      LINPTR(5)= 4
C
      DO 160 I= -9,-1
        MRKPTR(I)= -I
 160  CONTINUE
      MRKPTR(0)= 0
      MRKPTR(1)= 4
      MRKPTR(2)= 1
      MRKPTR(3)= 6
      MRKPTR(4)= 3
      MRKPTR(5)= 2
C
C     set current transformation number to default = 0
      CURNTN=0
C     set the open GKS flag
      GKSOPN = 1
C
      RETURN
      END
C
C
C
      SUBROUTINE   GOPWK
     I                  (WKID, CONID, WTYPE)
C
C     + + + PURPOSE + + +
C     open workstation, that is establish values about the work
C     station that will be needed later.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   WKID, CONID, WTYPE
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - workstation identifier, user choice
C     CONID  - connection identifier, use for file to write output to
C     WTYPE  - workstation type, predefined number selected by user
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX ONLY ONE WORKSTATION CAN BE USED AT A TIME')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKID .NE. 1) THEN
        WRITE(STDERR,2000)
        WKID = 1
        EFLAG= 1
      END IF
C
C     set the state value for GKS and WORKSTATION
      GKSOPN = 2
      WSSTAT(WKID) = 1
C
C     set type of workstation
      MONVEC(WKID) = WTYPE
C
C     set background and foreground global color values
C
      CFORE = IFRVEC(WKID)
      CBACK = IBKVEC(WKID)
C
C     set txpath to right
      TXPATH = GRIGHT
C
C     set horizontal text alignment to left
      TXALGH = GALEFT
C
C     set vertical text alignment to base
      TXALGV = GABASE
 
c     set x-component of character up vector
      CHARUX=0.0
 
c     set y-component of character up vector
      CHARUY=1.0
 
C
C     set text color
      TXCOLI = BRIGHTWHITE
C
C     set interior hatching style index to horizontal hatching
      FSINDX = HAT00
C
C     set interior style to hatched
      FSTYLE = HATCHED
C
      RETURN
      END
C
C
C
      SUBROUTINE   GACWK
     I                  (WKID)
C
C     + + + PURPOSE + + +
C     activate the workstation
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID
C
C     + + + ARGUMENT DEFINTIONS + + +
C     WKID - WORKSTATION ID NUMBER
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER    ERRIND
C
C     + + + FUNCTIONS + + +
      INTEGER      INFOGR
C
C     + + + EXTERNALS + + +
C      EXTERNAL   CKWKID, GETMON, SHINIT, GRINIT, GCLEAR, SCCLAL, GUNIT
      EXTERNAL   CKWKID, GETMON, SHINIT, GRINIT, GCLEAR,  GUNIT
      EXTERNAL   GHCSEL, GDEVIC, GCHJUS, GSTFNT, INFOGR
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Workstation number=',I5, ' not open. Cannot',
     #       ' activate in GACWK.')
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
C
C     get background color from the standard GKS location,
C     that is index zero in the current color table for the
C     workstaiton.
C
      CBACK= CLRTAB(WKID, 0)
C
      IF (WSSTAT(WKID).EQ.1) THEN
C       work station is open.  activate the station
C
C       clear AIDE screen
C   SCCLAL seems to be msiising from libraries  AWH 3-8-2000
C        CALL SCCLAL
C       init Interactor graphics
C  Use hardcopy devices only -- 3-10-2000 AWH
C  2=DXF,3=WMF,6=Postscript
        CALL SHINIT(' ')
        CALL GRINIT('H',1280,700,16)
        IF (MONVEC(WKID).EQ.2) THEN
C         output to DXF
          CALL GHCSEL (1,3)
          CALL GDEVIC ('mplot.dxf')
        ELSE IF (MONVEC(WKID).EQ.3) THEN
C         output to Windows Metafile
          CALL GHCSEL (1,1)
          CALL GDEVIC ('mplot.wmf')
        ELSE IF (MONVEC(WKID).EQ.6) THEN
C         output postscript file
          CALL GHCSEL (1,2)
          CALL IGrHardCopyOptions(7,0)
          CALL GDEVIC ('mplot.ps')
        END IF
C       get information for this workstation
        WRITE (99,*) 'INFOGR(7)  ',INFOGR(7)
        WRITE (99,*) 'INFOGR(30) ',INFOGR(30)
        WRITE (99,*) 'INFOGR(31) ',INFOGR(31)
        CALL GETMON(MONVEC(WKID), STDERR,
     O              ERRIND, MONWID(WKID), MONHGT(WKID),
     #              MONLX(WKID), MONLY(WKID), IFRVEC(WKID),
     #              IBKVEC(WKID))
C
C       clear Interactor graphics screen
        CALL GCLEAR
C       set interactor area based on graphics device width/height
        CALL GUNIT (0.0,0.0,MONWID(WKID),MONHGT(WKID))
C       use left justification for text
        CALL GCHJUS ('L')
C       set default character font and precision
        CALL GSTFNT(1,1)
C
C       set workstation scale factors to 1.0 to prevent
C       zero divides on user errors
        MXNXD = 1.0
        MYNYD = 1.0
C
C       set state values for GKS and workstation to indicate that
C       the work station is open and activated.
        GKSOPN = 3
        WSSTAT(WKID) = 2
      ELSE
C       problem
        WRITE(STDERR,2000) WKID
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTFNT
     I                   (FONT,PREC)
C
C     + + + PURPOSE + + +
C     choose a character set
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER    FONT,PREC
C
C     + + + LOCAL VARIABLES + + +
      INTEGER    IERR
C
C     + + + FUNCTIONS + + +
      INTEGER    INFOER
C
C     + + + EXTERNALS + + +
      EXTERNAL   GCHSET,INFOER
C
C     + + + END SPECIFICATIONS + + +
C
      IF (FONT .LE. 1) THEN
        CALL GCHSET ('simplexr.chr')
      ELSE IF (FONT .EQ. 2) THEN
        CALL GCHSET ('duplexr.chr')
      ELSE IF (FONT .EQ. 3) THEN
        CALL GCHSET ('triplexr.chr')
      ELSE IF (FONT .EQ. 4) THEN
        CALL GCHSET ('complexr.chr')
      END IF
      IERR= INFOER(1)
      IF (IERR.EQ.1 .OR. IERR.EQ.2) THEN
C       could not open character set
        WRITE (99,*) 'ERR:XXX GSTFNT could not open character set',FONT
      ELSE
C       looking good
        WRITE (99,*) 'INF:XXX GSTFNT using character set',FONT,IERR
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GETMON
     I                   (MONID, STDERR,
     O                    ERRIND, WIDTH, HEIGHT, PIXELX,
     #                    PIXELY, FOREC, BACKC)
C
C     + + + PURPOSE + + +
C     get information for the given monitor id
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   MONID, PIXELX, PIXELY, FOREC, BACKC,
     #          STDERR, ERRIND
      REAL      WIDTH, HEIGHT
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + FUNCTIONS + + +
      INTEGER   INFOSC
C
C     + + + EXTERNALS + + +
      EXTERNAL  INFOSC
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Monitor type=',I5,' is unknown.')
C
C     + + + END SPECIFICATIONS + + +
C
      WRITE(99,*) 'GETMOD:MONID:',MONID
      FOREC=1
      BACKC=0
      IF (MONID.LT.0 .OR. MONID.GT.20) THEN
C       monitor type unknown
        WRITE(STDERR,2000) MONID
        ERRIND = -1
      ELSE IF (MONID.EQ.2) THEN
C       laser jet - landscape
        WIDTH  = 10.5
        HEIGHT = 8.0
        PIXELX = 3150
        PIXELY = 2400
        WRITE(STDERR,*) 'GETMON:laser',PIXELX,PIXELY,WIDTH,HEIGHT
      ELSE IF (MONID.EQ.3) THEN
C       plotter
        WIDTH  = 10.5
        HEIGHT = 7.5
        PIXELX = 3360
        PIXELY = 2400
        WRITE(STDERR,*) 'GETMON:plotter',PIXELX,PIXELY,WIDTH,HEIGHT
      ELSE IF (MONID.EQ.4 .OR. MONID.EQ.6) THEN
C       postscript - landscape
        WIDTH  = 10.5
        HEIGHT = 7.5
        PIXELX = 3360
        PIXELY = 2400
        WRITE(STDERR,*) 'GETMON:postscript',PIXELX,PIXELY,WIDTH,HEIGHT
      ELSE
C     ok monitor
        WIDTH = 10.5
        HEIGHT = 8.0
        PIXELX = INFOSC(4)
        PIXELY = INFOSC(5)
        WRITE(STDERR,*) 'GETMON:monitor',PIXELX,PIXELY,WIDTH,HEIGHT
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GCLWK
     I                  (WKID)
C
C     + + + PURPOSE + + +
C     close workstation- that is bring back the orignial video
C     mode when the workstation was activated.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   WKID
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - WORKSTATION ID NUMBER
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNAL + + +
      EXTERNAL   CKWKID, GRQUIT, SHQUIT, GPAGE
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
C
C     shut down Interactor graphics
      CALL GPAGE (' ')
      CALL GRQUIT
      CALL SHQUIT(' ')
C     set the state value for GKS and WORKSTATION
      GKSOPN = 1
      WSSTAT(WKID) = 0
C
      RETURN
      END
C
C
C
      SUBROUTINE   GDAWK
     I                  (WKID)
C
C     + + + PURPOSE + + +
C     deactivate the workstation.  not clear what this means
C     in our current context.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   WKID
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - WORKSTATION ID NUMBER
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
C     do nothing until we can determine what this subroutine means
C
      RETURN
      END
C
C
C
      SUBROUTINE   GCLRWK
     I                   (WKID,COFL)
C
C     + + + PURPOSE + + +
C     clear workstation.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, COFL
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - workstation id number
C     COFL   - control flag for clearing action
C              1: clear screen but leave the plot in memory.
C              2: clear screen and the memory copy of it if any
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID, GCLEAR
C
C     + + + END SPECIFICATIONS + + +
C
      WRITE(STDERR,*) ' GCLRWK: WKID=',WKID
C
      CALL CKWKID(WKID)
C
C     clear Interactor graphics screen
      CALL GCLEAR
C
      RETURN
      END
C
C
C
      REAL FUNCTION   STRSIZ
     I                      (LCHRHD,CHARS)
C
C     + + + PURPOSE + + +
C     returns length of string in inches
C
C     + + + DUMMY ARGUMENTS + + +
      REAL          LCHRHD
      CHARACTER*(*) CHARS
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER     ITMP
      REAL        RTMP
C
C     + + + INTRINSICS + + +
      INTRINSIC   LEN,FLOAT
C
C     + + + OUTPUT FORMATS + + +
C2000 FORMAT (' strsiz:',I5,2F10.2,1X,A)
C
C     + + + END SPECIFICATIONS + + +
C
C     ???
      ITMP= LEN(CHARS)
      RTMP= ITMP* 1.0* LCHRHD/6.0
C
C     WRITE(STDERR,2000) ITMP,RTMP,LCHRHD,CHARS
C
      STRSIZ= RTMP
C
      RETURN
      END
C
C
C
      SUBROUTINE   LINWID
     I                   (LWIDE,THICK)
C
C     + + + PURPOSE + + +
C     set line width
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   LWIDE
      REAL      THICK
C
C     + + + ARGUMENT DEFINITIONS + + +
C     LWIDE  - 0 - use thick, >0 thickness in pixels
C     THICK  - line thickness in inches
C
C     + + + END SPECIFICATIONS + + +
C
C     **** nyi ****
C
      RETURN
      END
C
C
C
      SUBROUTINE   GPL
     I                (N,PX,PY)
C
C     + + + PURPOSE + + +
C     polyline- plot polyline in world coordinates
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  N
      REAL     PX(N),PY(N)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     N      - number of points to plot
C     PX     - array of x coordinates to plot
C     PY     - array of y coordinates to plot
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER   I, IERR, CLIP
      REAL      XL, XR, YL, YR, X(2), Y(2), XNEW(2), YNEW(2)
      REAL      CLRECT(4)
C
C     + + + FUNCTIONS + + +
      REAL      XNTOXD, YNTOYD, XWTOXV, YWTOYV
C
C     + + + EXTERNALS + + +
      EXTERNAL  XWTOXV, YNTOYD, XNTOXD, YWTOYV, LINWID, GCOLN, GLITYP
      EXTERNAL  GMOVEA, GLINEA
C
C     + + + END SPECIFICATIONS + + +
C
C     WRITE(99,*) 'gpl:',N,GLTYPE,LCOLOR
C     WRITE(99,*) '    ',PX(1),PX(N),PY(1),PY(N)
C
      CALL LINWID(0,PLWID)
      CALL GCOLN(LCOLOR)
C
C     do simple approach first,  add optional clipping second.
      XL = PX(1)
      YL = PY(1)
C     scale from world to device
      XL = XNTOXD(XWTOXV(XL))
      YL = YNTOYD(YWTOYV(YL))
C
C     set line type
      CALL GLITYP (GLTYPE)
C     move to the initial point
      CALL GMOVEA (XL,YL)
C     find out if clipping is on
      CALL GQCLIP(IERR,CLIP,CLRECT)
C     if clipping is not on, just plot the polyline
      IF(CLIP.EQ.GNCLIP) THEN
        DO 100 I=2,N
          XR = PX(I)
          YR = PY(I)
          XR = XNTOXD(XWTOXV(XR))
          YR = YNTOYD(YWTOYV(YR))
          CALL GLINEA (XR,YR)
 100    CONTINUE
C
C     else if clipping is on, go through the clipping filter
C     before drawing polyline segments
      ELSE
        CALL INRECT(PX(1),PY(1),CLRECT,LOC1)
        DO 200 I=2,N
        CALL INRECT(PX(I),PY(I),CLRECT,LOC2)
        X(1)=PX(I-1)
        X(2)=PX(I)
        Y(1)=PY(I-1)
        Y(2)=PY(I)
        XR= PX(I)
        YR= PY(I)
        XR= XNTOXD(XWTOXV(XR))
        YR= YNTOYD(YWTOYV(YR))
C
C... both points inside clipping rectangle
        IF(LOC1.EQ.0 .AND. LOC2.EQ.0) THEN
          CALL GLINEA (XR,YR)
C
C... first point inside, second point outside
        ELSE IF(LOC1.EQ.0 .AND. LOC2.NE.0) THEN
          CALL XYINT(LOC1,LOC2,CLRECT,X,Y,XNEW,YNEW,IERR)
          IF(IERR.EQ.0) THEN
            XRINT= XNTOXD(XWTOXV(XNEW(2)))
            YRINT= YNTOYD(YWTOYV(YNEW(2)))
            CALL GLINEA (XRINT,YRINT)
          END IF
C
C... first point outside, second point inside
        ELSE IF(LOC1.NE.0 .AND. LOC2.EQ.0) THEN
          CALL XYINT(LOC1,LOC2,CLRECT,X,Y,XNEW,YNEW,IERR)
          IF(IERR.EQ.0) THEN
            XRINT= XNTOXD(XWTOXV(XNEW(1)))
            YRINT= YNTOYD(YWTOYV(YNEW(1)))
            CALL GMOVEA (XRINT,YRINT)
            CALL GLINEA (XR,YR)
          END IF
C
C... both points outside (line still may pass through rectangle)
        ELSE IF(LOC1.NE.0 .AND. LOC2.NE.0) THEN
          CALL XYINT(LOC1,LOC2,CLRECT,X,Y,XNEW,YNEW,IERR)
          IF(IERR.EQ.0) THEN
            XRINT= XNTOXD(XWTOXV(XNEW(1)))
            YRINT= YNTOYD(YWTOYV(YNEW(1)))
            XR= XNTOXD(XWTOXV(XNEW(2)))
            YR= YNTOYD(YWTOYV(YNEW(2)))
            CALL GMOVEA (XRINT,YRINT)
            CALL GLINEA (XR,YR)
          END IF
        END IF
C
        LOC1=LOC2
C
200     CONTINUE
      END IF
C
      RETURN
      END
C
C
C
C     REAL FUNCTION   SRMIN
C    I                     (NPTS, VALUE)
C
C     + + + PURPOSE + + +
C     Find the minimum value in a vector
C
C     + + + DUMMY ARGUMENTS + + +
C     INTEGER   NPTS
C     REAL      VALUE(NPTS)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     NPTS   - number of items in vector value
C     VALUE  - vector with npnts items
C
C     + + + LOCAL VARIABLES + + +
C     INTEGER   I
C     REAL      TEMP
C
C     + + + INTRINSICS + + +
C     INTRINSIC   MIN
C
C     + + + END SPECIFICATIONS + + +
C
C     TEMP = 1.E30
C     DO 100 I=1,NPTS
C       TEMP = MIN(TEMP, VALUE(I))
C100  CONTINUE
C
C     SRMIN = TEMP
C
C     RETURN
C     END
C
C
C
C     REAL FUNCTION   SRMAX
C    I                     (NPTS, VALUE)
C
C     + + + PURPOSE + + +
C     Find the maximum value in a vector
C
C     + + + DUMMY ARGUMENTS + + +
C     INTEGER   NPTS
C     REAL      VALUE(NPTS)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     NPTS   - number of items in vector value
C     VALUE  - vector with npnts items
C
C     + + + LOCAL VARIABLES + + +
C     INTEGER   I
C     REAL      TEMP
C
C     + + + INTRINSICS + + +
C     INTRINSIC   MAX
C
C     + + + END SPECIFICATIONS + + +
C
C     TEMP = -1.E30
C     DO 100 I=1,NPTS
C       TEMP = MAX(TEMP, VALUE(I))
C100  CONTINUE
C
C     SRMAX = TEMP
C
C     RETURN
C     END
C
C
C
      SUBROUTINE   CKFAI
     M                  (FAI)
C
C     + + + PURPOSE + + +
C     check a fill area index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   FAI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     FAI    - fill area index to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX FAI=',I5,' > maximum of',I5,' or < 1.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (FAI.GT.MXNFAI .OR. FAI.LT.1) THEN
        WRITE(STDERR,2000) FAI, MXNFAI
        OKFLAG= NO
        EFLAG = 1
        FAI   = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKTALH
     M                   (TALH)
C
C     + + + PURPOSE + + +
C     check text hoizontal alingment
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TALH
C
C     + + + ARGUMENT DEFINITIONS + + +
C     TALH   - horizontal alignment code to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Text hor. align. index=',I5,' < 0 or >3.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (TALH.LT.GAHNOR .OR. TALH.GT.GARITE) THEN
        WRITE(STDERR,2000) TALH
        OKFLAG = NO
        EFLAG  = 1
        TALH   = GALEFT
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKFASI
     M                   (FASI)
C
C     + + + PURPOSE + + +
C     check fill area style index.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER FASI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     FASI   - fill area style index to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Fill area style index=',I5,' < -8 or >-1.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (FASI.LT.-8 .OR. FASI.GT.-1) THEN
        WRITE(STDERR,2000) FASI
        OKFLAG = NO
        EFLAG  = 1
        FASI   = -1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKFONT
     M                   (FONT)
C
C     + + + PURPOSE + + +
C     CHECK THE FONT CODE
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER FONT
C
C     + + + ARGUMENT DEFINITIONS + + +
C     FONT   - font number to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Font number=',I5,' < 0 or > 9.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
C
      IF (FONT.LT.0 .OR. FONT.GT.9) THEN
        WRITE(STDERR,2000) FONT
        OKFLAG = NO
        EFLAG  = 1
        FONT   = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKPREC
     M                   (PREC)
C
C     + + + PURPOSE + + +
C     check the text percision. not used but included to support any calls
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER PREC
C
C     + + + ARGUMENT DEFINITIONS + + +
C     PREC   - TEXT PRECISION CODE TO CHECK
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Precision code=',I5,' < 0 or > 2.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
C
      IF (PREC.LT.GSTRP .OR. PREC.GT.GSTRKP) THEN
        WRITE(STDERR,2000) PREC
        OKFLAG = NO
        EFLAG  = 1
        PREC   = GSTRP
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKMT
     M                 (MT)
C
C     + + + PURPOSE + + +
C     check the marker type code
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER MT
C
C     + + + ARGUMENT DEFINITIONS + + +
C     MT     - marker type code to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Marker type=',I5,' < -9 or > 5.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (MT.LT.-9 .OR. MT.GT.5) THEN
        WRITE(STDERR,2000) MT
        OKFLAG = NO
        EFLAG  = 1
        MT     = 0
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKWKID
     M                   (WKID)
C
C     + + + PURPOSE + + +
C     check the work station id
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - workstation id number to check. must always be 1.
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
 2000 FORMAT(/,' ERR:XXX WKID=',I5,' > maximum of',I5,' or < 1.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (WKID.GT.MXNWKS .OR. WKID.LT.1) THEN
        WRITE(STDERR,2000) WKID, MXNWKS
        OKFLAG = NO
        EFLAG  = 1
        WKID   = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKTXI
     M                  (TXI)
C
C     + + + PURPOSE + + +
C     check the text index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TXI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     TXI   - text index to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX TXI=',I5,' > maximum of',I5,' or < 1.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (TXI.GT.MXNTXI .OR. TXI.LT.1) THEN
        WRITE(STDERR,2000) TXI, MXNTXI
        OKFLAG = NO
        EFLAG  = 1
        TXI    = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKPLI
     M                  (PLI)
C
C     + + + PURPOSE + + +
C     CHECK THE POLYLINE INDEX
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER PLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     PLI    - POLYLINE INDEX TO CHECK
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX PLI=',I5,' > maximum of',I5,' or < 1.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (PLI.GT.MXNPLI .OR. PLI.LT.1) THEN
        WRITE(STDERR,2000) PLI, MXNPLI
        OKFLAG = NO
        EFLAG  = 1
        PLI    = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKPMI
     M                  (PMI)
C
C     + + + PURPOSE + + +
C     CHECK THE POLYMARKER INDEX
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER PMI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     PMI - polymarker index to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX PMI=',I5,' > maximum of',I5, ' or < 1')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (PMI.GT.MXNPMI .OR. PMI.LE.0) THEN
        WRITE(STDERR,2000) PMI, MXNPMI
        OKFLAG = NO
        EFLAG  = 1
        PMI    = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKTNR
     M                  (TNR)
C
C     + + + PURPOSE + + +
C     check the window, the normalization index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TNR
C
C     + + + ARGUMENT DEFINITIONS + + +
C     TNR    - transformation index to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX TNR=',I5,' > maximum of',I5,' or < 1')
 2010 FORMAT(/,' WRN:XXX Normalization transformation number= 0 ',
     #   'cannot be changed.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (TNR.EQ.0) THEN
        WRITE(STDERR,2010)
        WFLAG  = 1
      ELSE IF (TNR.GT.MXNTNR .OR. TNR.LT.1) THEN
        WRITE(STDERR,2000) TNR, MXNTNR
        OKFLAG = NO
        EFLAG  = 1
        TNR    = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   CKCI
     M                 (CI)
C
C     + + + PURPOSE + + +
C     check the color index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER CI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     CI - color index to check
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Color index=',I5,' < 0 or > 15.')
C
C     + + + END SPECIFICATIONS + + +
C
      OKFLAG = YES
      IF (CI.LT.0 .OR. CI.GT.15) THEN
        WRITE(STDERR,2000) CI
        OKFLAG = NO
        EFLAG  = 1
        CI     = LIGHTYELLOW
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQDSP
     I                  (DEVCOD,
     O                   ERR, DCUNIT, RX, RY, LX, LY)
C
C     + + + PURPOSE + + +
C     inquire about the display characteristics
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER DEVCOD, ERR, DCUNIT, LX, LY
      REAL    RX, RY
C
C     + + + ARGUMENT DEFINITIONS + + +
C     DEVCND - work station type-integer*4 defines a particular
C              plotting device
C     ERR    - 0 no error, 8 system not opened, 22- invalid
C     DCUNIT - 0 meters, 1 other
C     RX, RY - max hor and vertical size, convient units
C     LX, LY - max hor and vertical size, raster units, pixels
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER WKID
C
C     + + + DATA INITIALIZATIONS + + +
      DATA WKID/1/
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX GQDSP cannot respond because no workstation',
     #       ' is open.')
 2010 FORMAT(/,' ERR:XXX GQDSP expected display type=',I5,' but found',
     #  'display type=',I5,' instead.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.LT.2) THEN
        WRITE(STDERR,2000)
        ERR   = 8
        EFLAG = 1
        RETURN
      END IF
 
C     ONLY ONE WORKSTATION CAN BE OPEN AND IT MUST BE WKID=1.
      IF (DEVCOD.NE.MONVEC(WKID)) THEN
        WRITE(STDERR,2010) DEVCOD, MONVEC(WKID)
        ERR   = 22
        EFLAG = 1
        RETURN
      END IF
 
C     UNITS ARE NOT METERS- THEY ARE INCHES
      DCUNIT = 1
      RX  = MONWID(WKID)
      RY  = MONHGT(WKID)
      LX  = MONLX(WKID)
      LY  = MONLY(WKID)
      ERR = 0
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQCHB
     O                  (ERRIND, CHBX, CHBY)
C
C     + + + PURPOSE + + +
C     inquire character base vector.  not clear why this is
C     needed but it is requested.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND
      REAL CHBX, CHBY
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRIND - error indicator
C     CHBX   - character base vector horizontal component
C     CHBY   - character base vector vertical component
C
c     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.NE.3) THEN
        ERRIND = 8
        EFLAG  = 1
      ELSE
        ERRIND = 0
        CHBX   = CHARBX
        CHBY   = CHARBY
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GCLKS
C
C     + + + PURPOSE + + +
C     stop working with GKS
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' Please check error file.  Errors have been logged.')
 2010 FORMAT(/,' Please check error file.  Warnings have been logged.')
C
C     + + + END SPECIFICATIONS + + +
C
c      IF (EFLAG.NE.0) THEN
c        WRITE(*,2000)
c      END IF
c      IF (WFLAG.NE.0) THEN
c        WRITE(*,2010)
c      END IF
      CLOSE(STDERR)
      GKSOPN = 0
C
      RETURN
      END
C
C
C
      SUBROUTINE   GESC
     I                 (FCTID, LIDR, IDR, MODR, LODR, ODR)
C
C     + + + PURPOSE + + +
C     ???
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER FCTID, LIDR, MODR,  LODR
      CHARACTER*80 IDR(LIDR), ODR(MODR)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ESCAPE - standard way of performing non-standard functions
C     make dummy for now
C     FCTID  -
C     LIDR   -
C     IDR    -
C     MODR   -
C     LODR   -
C     ODR    -
C
C     + + + END SPECIFICATIONS + + +
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSWN
     M                 (TNR,
     I                  XMIN, XMAX, YMIN, YMAX)
C
C     + + + PURPOSE + + +
C     Set window in world coordinates
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   TNR
      REAL      XMIN, XMAX, YMIN, YMAX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
      INTEGER N, ERRIND
 
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKTNR
C
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKTNR(TNR)
 
C     inquire to GKS to get the current (selected) transformation number
      CALL GQCNTN(ERRIND,N)
C
      XWMINV(TNR) = XMIN
      XWMAXV(TNR) = XMAX
      YWMINV(TNR) = YMIN
      YWMAXV(TNR) = YMAX
C     if the the current (selected) transformation is being redefined, reset
C     the scalar min/max variables
      IF(TNR.EQ.N) THEN
        XWMIN=XWMINV(TNR)
        XWMAX=XWMAXV(TNR)
        YWMIN=YWMINV(TNR)
        YWMAX=YWMAXV(TNR)
      END IF
 
C     attempt to set the scale factors
      IF (ABS(XVMINV(TNR)).GT.1.0E-30 .OR.
     1    ABS(XVMAXV(TNR)).GT.1.0E-30) THEN
C       viewport is known
        MXWXVV(TNR) = (XVMAXV(TNR) - XVMINV(TNR))/(XMAX - XMIN)
        MYWYVV(TNR) = (YVMAXV(TNR) - YVMINV(TNR))/(YMAX - YMIN)
        IF(TNR.EQ.N) THEN
          MXWXV=MXWXVV(TNR)
          MYWYV=MYWYVV(TNR)
        END IF
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSVP
     M                 (TNR,
     I                  XMIN, XMAX, YMIN, YMAX)
C
C     + + + PURPOSE + + +
C     set the viewpoint in normalized device co-ordinates of the
C     specified normalization transformation.  note:this sets the
C     relationship between the aspect of the world view and the
C     aspect of all other representations.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TNR
      REAL XMIN, XMAX, YMIN, YMAX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
      INTEGER N, ERRIND
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKTNR
C
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKTNR(TNR)
 
C     inquire to GKS to get the current (selected) transformation number
      CALL GQCNTN(ERRIND,N)
C
      XVMINV(TNR) = XMIN
      XVMAXV(TNR) = XMAX
      YVMINV(TNR) = YMIN
      YVMAXV(TNR) = YMAX
C     if the the current (selected) transformation is being redefined, reset
C     the scalar min/max variables
      IF(TNR.EQ.N) THEN
        XVMIN=XVMINV(TNR)
        XVMAX=XVMAXV(TNR)
        YVMIN=YVMINV(TNR)
        YVMAX=YVMAXV(TNR)
      END IF
C     attempt to set the scale factors
      IF (ABS(XWMINV(TNR)).GT.1.0E-30 .OR.
     1    ABS(XWMAXV(TNR)).GT.1.0E-30) THEN
C       viewport is known
        MXWXVV(TNR) = (XMAX - XMIN)/(XWMAXV(TNR) - XWMINV(TNR))
        MYWYVV(TNR) = (YMAX - YMIN)/(YWMAXV(TNR) - YWMINV(TNR))
        IF(TNR.EQ.N) THEN
          MXWXV=MXWXVV(TNR)
          MYWYV=MYWYVV(TNR)
        END IF
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSWKWN
     ?                   (WKID, XMIN, XMAX, YMIN, YMAX)
C
C     + + + PURPOSE + + +
C     set the workstation window and compute scale factors if
C     possible
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID
      REAL XMIN, XMAX, YMIN, YMAX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID
C
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + END SPECIFICATIONS + + +
c
      CALL CKWKID(WKID)
      XNMINV(WKID) = XMIN
      XNMAXV(WKID) = XMAX
      YNMINV(WKID) = YMIN
      YNMAXV(WKID) = YMAX
      XNMIN = XMIN
      XNMAX = XMAX
      YNMIN = YMIN
      YNMAX = YMAX
C      CALL GAREA (XMIN,YMIN,XMAX,1.0)
      WRITE(99,*) 'GSWKWN:',XMIN,XMAX,YMIN,YMAX
      IF (ABS(XNMINV(WKID)).GT.1.0E-30 .OR.
     1   ABS(XNMAXV(WKID)).GT.1.0E-30) THEN
        IF (ABS(XDMINV(WKID)).GT.1.0E-30 .OR.
     1     ABS(XDMAXV(WKID)).GT.1.0E-30) THEN
C         we can compute the scale factors
          MXNXD = (XDMAXV(WKID) - XDMINV(WKID))/
     A            (XNMAXV(WKID) - XNMINV(WKID))
          MYNYD = (YDMAXV(WKID) - YDMINV(WKID))/
     A            (YNMAXV(WKID) - YNMINV(WKID))
        END IF
      END IF
      WRITE(99,*) '      :',MXNXD,MYNYD
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSWKVP
     M                   (WKID,
     I                    XMIN, XMAX, YMIN, YMAX)
C
C     + + + PURPOSE + + +
C     set the workstation viewport
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID
      REAL XMIN, XMAX, YMIN, YMAX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID
C     EXTERNAL   GUNIT
C
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
      XDMINV(WKID) = XMIN
      XDMAXV(WKID) = XMAX
      YDMINV(WKID) = YMIN
      YDMAXV(WKID) = YMAX
      XDMIN = XMIN
      XDMAX = XMAX
      YDMIN = YMIN
      YDMAX = YMAX
C      CALL GUNIT (XMIN,YMIN,XMAX,YMAX)
      WRITE(99,*) 'GSWKVP:',XMIN,XMAX,YMIN,YMAX
      IF (ABS(XNMINV(WKID)).GT.1.0E-30 .OR.
     1   ABS(XNMAXV(WKID)).GT.1.0E-30) THEN
        IF (ABS(XDMINV(WKID)).GT.1.0E-30 .OR.
     1     ABS(XDMAXV(WKID)).GT.1.0E-30) THEN
C         we can compute the scale factors
          MXNXD = (XDMAXV(WKID) - XDMINV(WKID))/
     A            (XNMAXV(WKID) - XNMINV(WKID))
          MYNYD = (YDMAXV(WKID) - YDMINV(WKID))/
     A            (YNMAXV(WKID) - YNMINV(WKID))
        END IF
      END IF
      WRITE(99,*) '      :',MXNXD,MYNYD
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSELNT
     I                   (TNR)
C
C     + + + PURPOSE + + +
C     Select normalization transformation.  Define the global
C     values for the co-ordinate transformations
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TNR
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKTNR
C
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Scale factor for Norm. tran. number=',I5,
     #       /,5X,' x-axis undefined.')
 2010 FORMAT(/,' ERR:XXX Scale factor for Norm. tran. number=',I5,
     #       /,5X,' y-axis undefined.')
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKTNR(TNR)
      CURNTN=TNR
      XWMIN = XWMINV(TNR)
      XWMAX = XWMAXV(TNR)
      YWMIN = YWMINV(TNR)
      YWMAX = YWMAXV(TNR)
      XVMIN = XVMINV(TNR)
      XVMAX = XVMAXV(TNR)
      YVMIN = YVMINV(TNR)
      YVMAX = YVMAXV(TNR)
      MXWXV = MXWXVV(TNR)
      MYWYV = MYWYVV(TNR)
 
      IF (ABS(MXWXV).LT.1.0E-30) THEN
        WRITE(STDERR,2000) TNR
        EFLAG = 1
        MXWXV = 1.0
      END IF
      IF (ABS(MYWYV).LT.1.0E-30) THEN
        WRITE(STDERR,2010) TNR
        EFLAG = 1
        MYWYV = 1.0
      END IF
C
      RETURN
      END
C
C
C
      REAL FUNCTION   XWTOXV
     I                      (XW)
C
C     + + + PURPOSE + + +
C     transform an x-axis value from world to NDC
C
C     + + + DUMMY ARGUMENTS + + +
      REAL XW
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      XWTOXV = XVMIN + MXWXV*(XW - XWMIN)
C
      RETURN
      END
C
C
C
      REAL FUNCTION   XVTOXW
     I                      (XV)
C
C     + + + PURPOSE + + +
C     transform an x-axis value from NCD to world
C
C     + + + DUMMY ARGUMENTS + + +
      REAL XV
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      XVTOXW = XWMIN + (XV - XVMIN)/MXWXV
C
      RETURN
      END
C
C
C
      REAL FUNCTION   XNTOXD
     I                      (XN)
C
C     + + + PURPOSE + + +
C     transform an x-axis value from NDC to device
C
C     + + + DUMMY ARGUMENTS + + +
      REAL XN
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      XNTOXD = XDMIN + MXNXD*(XN - XNMIN)
C
      RETURN
      END
C
C
C
      REAL FUNCTION   YWTOYV
     I                      (YW)
C
C     + + + PURPOSE + + +
C     transform a y-axis value from world to NDC
C
C     + + + DUMMY ARGUMENTS + + +
      REAL YW
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
 
      YWTOYV = YVMIN + MYWYV*(YW - YWMIN)
C
      RETURN
      END
C
C
C
      REAL FUNCTION   YVTOYW
     I                      (YV)
C
C     + + + PURPOSE + + +
C     transform a y-axis value from NDC to world
C
C     + + + DUMMY ARGUMENTS + + +
      REAL YV
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
 
      YVTOYW = YWMIN + (YV - YVMIN)/MYWYV
C
      RETURN
      END
C
C
C
      REAL FUNCTION   YNTOYD
     I                      (YN)
C
C     + + + PURPOSE + + +
C     transform a y-axis value from NDC to device
C
C     + + + DUMMY ARGUMENTS + + +
      REAL YN
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
 
      YNTOYD = YDMIN + MYNYD*(YN - YNMIN)
C
      RETURN
      END
C
C
C
      REAL FUNCTION   XDTOXN
     I                      (XD)
C
C     + + + PURPOSE + + +
C     transform a x-axis value from device to NDC
C
C     + + + DUMMY ARGUMENTS + + +
      REAL XD
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      XDTOXN = XNMIN + (XD - XDMIN)/MXNXD
C
      RETURN
      END
C
C
C
      REAL FUNCTION   YDTOYN
     I                      (YD)
C
C     + + + PURPOSE + + +
C     transform a y-axis value from device to NDC
C
C     + + + DUMMY ARGUMENTS + + +
      REAL YD
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
 
      YDTOYN = YNMIN + (YD - YDMIN)/MYNYD
C
      RETURN
      END
C
C
C
      SUBROUTINE   GPM
     I                (N, PX, PY)
C
C     + + + PURPOSE + + +
C     polymarker - uses non-standard option flag.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   N
      REAL      PX(N), PY(N)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     N      - number of points to plot
C     PX     - array of x coordinates to plot
C     PY     - array of y coordinates to plot
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
      INCLUDE 'gksprm.inc'
C
C     + + + LOCAL VARIABLES + ++
      INTEGER   I, CLIP, IERR
      REAL      XWTOXV, YWTOYV, XNTOXD, YNTOYD,
     $          XDL, YDL, XDR, YDR, D, CLRECT(4)
C
C     + + + EXTERNALS + + +
      EXTERNAL  XWTOXV, YWTOYV, XNTOXD, YNTOYD, GCOLN, GMRKRA, GCHSIZ
C
C     + + + END SPECIFICATIONS + + +
C
C     set the foreground color for the marker
      CALL GCOLN (MCOLOR)
C     set marker size
      CALL GCHSIZ(MARKH,MARKH)
C
      XDL = XNTOXD(XWTOXV(PX(1)))
      YDL = YNTOYD(YWTOYV(PY(1)))
C
C     draw the marker -- skip marker if it is out of clipping rectangle and
C     clipping is on.
      LOC=0
      CALL GQCLIP(IERR,CLIP,CLRECT)
      IF(CLIP.EQ.GCLIP .AND. IERR.EQ.0)
     *   CALL INRECT(PX(1),PY(1),CLRECT,LOC)
      IF(LOC.EQ.0) CALL GMRKRA (XDL,YDL,MTYPE)
C
      DO 100 I=2,N
C     check for clipping
      LOC=0
      CALL GQCLIP(IERR,CLIP,CLRECT)
      IF(CLIP.EQ.GCLIP .AND. IERR.EQ.0)
     *   CALL INRECT(PX(I),PY(I),CLRECT,LOC)
 
C     draw markerS unless marker is to be clipped
      IF(LOC.EQ.0) THEN
C       scale to the ndc
        XDR = XNTOXD(XWTOXV(PX(I)))
        YDR = YNTOYD(YWTOYV(PY(I)))
C
        IF (MRKOPT.EQ.1) THEN
C         find square of straightline distance from last point marked
          D = (XDR - XDL)**2 + (YDR - YDL)**2
          WRITE(STDERR,*) ' D=',D, 4.*MARKH**2
          IF (D .GT. 4.0*MARKH**2) THEN
C           mark the point- it is more than twice the marker height
C           away from the center of the previous marker
C           draw the marker
            CALL GMRKRA (XDR,YDR,MTYPE)
C           UPDATE THE LAST POINT MARKED
            XDL = XDR
            YDL = YDR
          END IF
        ELSE
C         mark every point
          CALL GMRKRA (XDR,YDR,MTYPE)
        END IF
      END IF
 100  CONTINUE
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSPLR
     O                  (WKID, PLI,
     I                   LTYP, LWID, COLI)
C
C     + + + PURPOSE + + +
C     set polyline representation
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, PLI, LTYP, COLI
      REAL LWID
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKPLI, CKWKID, CKCI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' WRN:XXX Only FULL lines supported now. Line type set',
     #       ' to 1.')
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKPLI(PLI)
      CALL CKWKID(WKID)
      CALL CKCI(COLI)
      IF (LTYP.NE.1) THEN
        WRITE(STDERR,2000)
        LTYP = FULL
      END IF
 
      LTYPE(WKID,PLI) =  LTYP
      LWIDTH(WKID,PLI) = LWID
      ARPLCI(WKID,PLI) = COLI
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSPLI
     I                  (INDEX)
C
C     + + + PURPOSE + + +
C     set polyline index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   INDEX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     INDEX  - ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKPLI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Invalid line type=',I5,' GSPLI. Reset to',I3)
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKPLI(INDEX)
C
      IF (WKMODE(1).EQ.GBUNDL) THEN
        IF (GLTYPE.GE.1 .AND. GLTYPE.LE.5) THEN
C         set the pattern for the line
          GLTYPE= LINPTR(LTYPE(1,INDEX))
        ELSE
          WRITE(STDERR,2000) GLTYPE,FULL
          EFLAG = 1
          GLTYPE= FULL
        END IF
      END IF
C
      IF (WKMODE(2) .EQ. GBUNDL) THEN
        PLWID  = BSLINW*LWIDTH(1,INDEX)
      END IF
C
      IF (WKMODE(3) .EQ. GBUNDL) THEN
        LCOLOR = CLRTAB(1,ARPLCI(1,INDEX))
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSCR
     I                 (WKID, CI, CR, CG, CB)
C
C     + + + PURPOSE + + +
C     set color representation. also set background color if CI=0
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, CI, N, IRED, IGREEN, IBLUE
      REAL CR, CG, CB
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID, CKCI
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
C      CALL CKCI(CI)
      IF (CI.LT.0 .OR. CI.GT.15) RETURN
      N = CLRTAB(WKID,CI)
      CLRRED(WKID,CI) = CR
      CLRGRN(WKID,CI) = CG
      CLRBLU(WKID,CI) = CB
      IRED= 255*CR
      IGREEN= 255*CG
      IBLUE= 255*CB
      IF(IRED.GT.255) IRED=255
      IF(IRED.LT.0) IRED=0
      IF(IGREEN.GT.255) IGREEN=255
      IF(IGREEN.LT.0) IGREEN=0
      IF(IBLUE.GT.255) IBLUE=255
      IF(IBLUE.LT.0) IBLUE=0
      CALL GPARGB(N,IRED,IGREEN,IBLUE)
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSPMR
     O                  (WKID, PMI,
     I                   MTYP, MSZSF, COLI)
C
C     + + + PURPOSE + + +
C     set polymarker representation
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, PMI, MTYP, COLI
      REAL MSZSF
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID, CKPMI, CKCI, CKMT
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
      CALL CKPMI(PMI)
      CALL CKCI(COLI)
      CALL CKMT(MTYP)
      ARMT(WKID,PMI)   = MRKPTR(MTYP)
      ARMS(WKID,PMI)   = MSZSF
      ARPMCI(WKID,PMI) = COLI
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSPMI
     I                  (INDEX)
C
C     + + + PURPOSE + + +
C     set polymarker index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER INDEX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKPMI
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKPMI(INDEX)
      IF (WKMODE(4).EQ.GBUNDL) THEN
        MTYPE  = ARMT(1,INDEX)
      END IF
      IF (WKMODE(5).EQ.GBUNDL) THEN
        MARKH  = BSMRKH*ARMS(1,INDEX)
      END IF
      IF (WKMODE(6).EQ.GBUNDL) THEN
        MCOLOR = CLRTAB(1,ARPMCI(1,INDEX))
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSCHH
     I                  (CHH)
C
C     + + + PURPOSE + + +
C     set character height- in world units.  unclear as to
C     what this means when the characters are not vertical or
C     horizontal.  we will convert to device units here
C     remember only one work station can be open at a time
C     in this simple version of GKS.  Therefore conversion to
C     device co-ordinates is always possible!
 
C     the information I have on GKS does not make clear which
C     of the two world values are to be used for character
C     height!  I assume that the vertical, y, direction is always
C     used, no matter what the orientation of the text is to be.
C
C     + + + DUMMY ARGUMENTS + + +
      REAL CHH
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      CHARH  = CHH
      CHARHD = 50.0*CHARH*MYWYV
C
C     WRITE(99,*) 'GSCHH:',CHARH,MYWYV,MYNYD,CHARHD
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSCHUP
     I                   (CHUX, CHUY)
C
C     + + + PURPOSE + + +
C     set character up vector
C
C     + + + DUMMY ARGUMENTS + + +
      REAL CHUX, CHUY
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      DOUBLE PRECISION DXV, DYV, THETA, FAC
C
C     + + + INTRINSICS + + +
      INTRINSIC   DBLE, DATAN2, ABS
C
C     + + + DATA INITIALIZATIONS + + +
      DATA FAC/57.29577951/
C
C     + + + END SPECIFICATIONS + + +
      CHARUX = CHUX
      CHARUY = CHUY
 
C     CONVERT TO NDC CO-ORDINATES AND THEN DETERMINE THE ANGLE.
      DXV    = MXWXV*DBLE(CHARUX)
      DYV    = MYWYV*DBLE(CHARUY)
      THETA  = FAC*DATAN2(DYV, DXV)
      IF (THETA.LT.0) THETA = THETA + 360.D0
      TXANGL = THETA - 90.
      IF (ABS(TXANGL).LE.1.E-5) TXANGL = 0.E0
      IF (TXANGL.LT.0.0)        TXANGL = TXANGL + 360.
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTXP
     M                  (TXP)
C
C     + + + PURPOSE + + +
C     set text path
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TXP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Text path code=',I5,' not yet supported.',
     #        /,5X,'Only support text path:right.')
C
C     + + + END SPECIFICATIONS + + +
C
C     only support characters from right to left relative to the
C     character up vector at this time
      IF (TXP.NE.GRIGHT) THEN
        WRITE(STDERR,2000) TXP
        EFLAG = 1
        TXP   = GRIGHT
      END IF
      TXPATH = TXP
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTXAL
     O                   (TXALH, TXALV)
C
C     + + + PURPOSE + + +
C     set text alignment
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER TXALH, TXALV
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKTALH
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Vertical text alignment code=',I5,' not yet',
     #   'supported.',/,5X,'Only support vert. text alignm: base.')
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKTALH(TXALH)
      IF (OKFLAG.EQ.YES) THEN
        TXALGH = TXALH
      ELSE
        TXALGH = GALEFT
      END IF
      IF (TXALV.NE.GABASE.AND.TXALV.NE.GAVNOR) THEN
        WRITE(STDERR,2000) TXALV
        EFLAG  = 1
        TXALGV = GABASE
      END IF
      TXALGV = GABASE
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTXI
     I                  (INDEX)
C
C     + + + PURPOSE + + +
C     set text index.  since only one workstation is permitted
C     using the SVS graphics, this subroutine will set
C     global values directly.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER INDEX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKTXI, GSTFNT
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKTXI(INDEX)
      TXINDX = INDEX
      IF (WKMODE(7).EQ.GBUNDL) THEN
        TXFONT = TXFNTA(1,INDEX)
        TXPREC = TXPRCA(1,INDEX)
        CALL GSTFNT (TXFONT,TXPREC)
      END IF
      IF (WKMODE(8).EQ.GBUNDL) THEN
        TXEXPF = ARCEF(1,INDEX)
      END IF
      IF (WKMODE(9).EQ.GBUNDL) THEN
         TXSPCF = ARCS(1,INDEX)
      END IF
      IF (WKMODE(10).EQ.GBUNDL) THEN
         TXCOLI = CLRTAB(1, ARTCI(1,INDEX))
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSCLIP
     I                   (CLSW)
C
C     + + + PURPOSE + + +
C     set clipping indicator
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER CLSW
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000    FORMAT(/,' WRN:XXX Clipping indicator neither CLIP nor NOCLIP',
     #       ' in GSCLIP.',/,5X,'NOCLIP used.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (CLSW.NE.GNCLIP.AND.CLSW.NE.GCLIP) THEN
        WRITE(STDERR,2000) CLSW
        WFLAG  = 1
        CLIPIT = GNCLIP
      ELSE
        CLIPIT = CLSW
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTXR
     O                  (WKID, TXI,
     I                   FONT, PREC, CHXP, CHSP, COLI)
C
C     + + + PURPOSE + + +
C     set text representation
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, TXI, FONT, PREC, COLI
      REAL CHXP, CHSP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID, CKTXI, CKFONT, CKCI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Text precision=',I5,' < 0 or > 2.')
 2010 FORMAT(/,' WRN:XXX Text precision ignored in this GKS interface.')
 2020 FORMAT(/,' WRN:XXX In GSTXR character spacing change not',
     #       ' supported.')
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
      CALL CKTXI(TXI)
C        TXFONT -I*4- TEXT FONT NUMBER
C        TXPREC -I*4- TEXT PRECISION NUMBER; 0 STRING, 1 CHAR, 2 STROKE
C        ARCEF   R*4 -TEXT EXPANSION FACTOR- RELATIVE NUMBER
C        ARCS    R*4  TEXT SPACING FACTOR
C        ARTCI   I*4  POINTER TO THE CURRENT COLOR TABLE: 0-15
C
C
      CALL CKFONT(FONT)
      TXFNTA(WKID,TXI) = FONT
C
      IF (PREC.LT.0 .OR. PREC.GT.2) THEN
        WRITE(STDERR,2000) PREC
        EFLAG = 1
        TXPRCA(WKID,TXI) = 0
        WFLAG = 1
        WRITE(STDERR,2010)
      ELSE
        TXPRCA(WKID,TXI) = PREC
        WFLAG = 1
        WRITE(STDERR,2010)
      END IF
      ARCEF(WKID,TXI) = CHXP
      ARCS(WKID,TXI)  = CHSP
      WRITE(STDERR,2020)
      WFLAG = 1
C
      CALL CKCI(COLI)
      ARTCI(WKID,TXI) = COLI
C
      RETURN
      END
C
C
C
      SUBROUTINE   GTX
     I                (PX, PY, CHARS)
C
C     + + + PURPOSE + + +
C     Output graphics text.
C
C     + + + DUMMY ARGUMENTS + + +
      REAL          PX, PY
      CHARACTER*(*) CHARS
C
C     + + + ARGUMENT DEFINITIONS + + +
C     PX     - x coordinate for start of text
C     PX     - y coordinate for start of text
C     CHARS  - text being output
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
      INCLUDE 'gksprm.inc'
C
C     + + + LOCAL VARIABLES + + +
      REAL       XD, YD, SLEN, CLRECT(4)
      INTEGER CLIP, IERR
C
C     + + + FUNCTIONS + + +
      REAL       XNTOXD, YNTOYD, XWTOXV, YWTOYV, STRSIZ
C
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + EXTERNALS + + +
      EXTERNAL   XWTOXV, YNTOYD, XNTOXD, YWTOYV, STRSIZ
      EXTERNAL   GCOLN, GCHSIZ, GCHROT, GCHOUA, GLITYP
C
C     + + + END SPECIFICATIONS + + +
C
C     set base vector values in common
      CHARBX = PX
      CHARBY = PY
C
C     implement crude clipping -- if the text point is out of the clipping
C     rectangle, do not draw the text.
      CALL GQCLIP(IERR,CLIP,CLRECT)
      IF(CLIP.EQ.GCLIP .AND. IERR.EQ.0) THEN
        CALL INRECT(PX,PY,CLRECT,LOC)
        IF(LOC.NE.0) RETURN
      END IF
 
      XD = XNTOXD(XWTOXV(PX))
      YD = YNTOYD(YWTOYV(PY))
C
C     make adjustments for alignment support so far
      IF (TXPATH.EQ.0) THEN
        IF (TXALGH.EQ.1 .OR. TXALGH.EQ.0) THEN
        ELSE IF (TXALGH.EQ.2) THEN
C         center the string on the point
          SLEN = STRSIZ(CHARHD, CHARS)
          XD = XD - 0.5*SLEN
        ELSE
C         set string so point is in the right
          SLEN = STRSIZ(CHARHD, CHARS)
          XD = XD - SLEN
        END IF
      END IF
C
C     set color, size, and rotation
      CALL GCOLN (TXCOLI)
      CALL GCHSIZ (CHARHD,CHARHD)
      CALL GCHROT (TXANGL)
C     set line type to solid
      CALL GLITYP (0)
C     output the text
C     WRITE(99,*) 'gtx:',XD,YD,CHARS
      CALL GCHOUA (XD,YD,CHARS)
C     set line type to user spec
      CALL GLITYP (GLTYPE)
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSLN
     I                 (LTYP)
C
C     + + + PURPOSE + + +
C     set line type - individual access
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER LTYP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSLN working mode is: bundled.')
 2010 FORMAT(/,' ERR:XXX Invalid line type=',I5,
     #       ' in GSLN. Reset to',I3)
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(1).EQ.GINDIV) THEN
        IF (LTYP.GE.1.AND.LTYP.LE.5) THEN
C         set the pattern for the line
          GLTYPE= LINPTR(LTYP)
        ELSE
C         unknown pattern, set to solid
          WRITE(STDERR,2010) GLTYPE, FULL
          EFLAG = 1
          GLTYPE= FULL
        END IF
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSLWSC
     I                   (LWID)
C
C     + + + PURPOSE + + +
C     set linewidth scale factor- individual
C
C     + + + DUMMY ARGUMENTS + + +
      REAL LWID
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSLWSC working mode is: bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(2).EQ.GINDIV) THEN
        PLWID = LWID*BSLINW
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSPLCI
     I                   (COLI)
C
C     + + + PURPOSE + + +
C     set polyline color index
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER COLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKCI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSPLCI working mode is: bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(3).EQ.GINDIV) THEN
        CALL CKCI(COLI)
        LCOLOR = CLRTAB(1,COLI)
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSMK
     I                 (MTYP)
C
C     + + + PURPOSE + + +
C     set marker type
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER MTYP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKMT
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In MTYP working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(4).EQ.GINDIV) THEN
        CALL CKMT(MTYP)
        MTYPE = MRKPTR(MTYP)
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSMKSC
     I                   (MSZSF)
C
C     + + + PURPOSE + + +
C     set marker scale factor
C
C     + + + DUMMY ARGUMENTS + + +
      REAL MSZSF
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSMKSC working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(5).EQ.GINDIV) THEN
        MARKSF = MSZSF
C       SET THE CURRENT MARKER HEIGHT DIRECTLY
        MARKH = MARKSF
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSPMCI
     I                   (COLI)
C
C     + + + PURPOSE + + +
C     set polymarker color index individual
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER COLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKCI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSPMCI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(6).EQ.GINDIV) THEN
        CALL CKCI(COLI)
        MCOLOR = CLRTAB(1,COLI)
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTXFP
     I                   (FONT, PREC)
C
C     + + + PURPOSE + + +
C     set text font and precision individual
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER FONT, PREC
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKFONT, CKPREC, GSTFNT
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSTXFP working mode is:bundled.')
 2010 FORMAT(/,' WRN:XXX In GSTXFP text precision ignored.  Only the',
     #       ' font number',/,5X, 'has meaning in this GKS interface.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(7).EQ.GINDIV) THEN
        CALL CKFONT(FONT)
        CALL CKPREC(PREC)
        TXFONT = FONT
        TXPREC = PREC
        CALL GSTFNT (TXFONT,TXPREC)
        WRITE(STDERR,2010)
        WFLAG = 1
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSCHXP
     I                    (CHXP)
C
C     + + + PURPOSE + + +
C     set character expansion factor individual
C
C     + + + DUMMY ARGUMENTS + + +
      REAL CHXP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   SETASP
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSCHXP working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(8).EQ.GINDIV) THEN
        TXEXPF = CHXP
        CALL SETASP(TXEXPF)
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSCHSP
     I                   (CHSP)
C
C     + + + PURPOSE + + +
C     set character spacing individual. variable character spacing
C     not supported
C
C     + + + DUMMY ARGUMENTS + + +
      REAL CHSP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSCHSP working mode is:bundled.')
 2010 FORMAT(/,' WRN:XXX In GSCHCP character spacing change not',
     #      ' supported.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(9).EQ.GINDIV) THEN
        TXSPCF = CHSP
        WRITE(STDERR,2010)
        WFLAG = 1
      ELSE
        WRITE(STDERR,2000)
        WRITE(STDERR,2010)
        EFLAG = 1
        WFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSTXCI
     I                   (COLI)
C
C     + + + PURPOSE + + +
C     set text color index individual
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER COLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKCI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSTXCI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(10).EQ.GINDIV) THEN
        CALL CKCI(COLI)
        TXCOLI = CLRTAB(1,COLI)
      ELSE
        WRITE(STDERR, 2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSFAIS
     I                   (INTS)
C
C     + + + PURPOSE + + +
C     set fill area interior style individual.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER INTS
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSFAIS working mode is:bundled.')
 2010 FORMAT(/,' ERR:XXX Fill area style must be: HOLLOW, HATCHED,',
     #         ' or SOLID.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(11).EQ.GINDIV) THEN
        IF (INTS.NE.HOLLOW .AND. INTS.NE.HATCHED .AND.
     $      INTS.NE.SOLID .AND. INTS.NE.XHATCH) THEN
          WRITE(STDERR,2010)
          EFLAG = 1
        ELSE
          FSTYLE = INTS
        END IF
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSFASI
     I                   (STYLI)
C
C     + + + PURPOSE + + +
C     set fill area style index individual
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER STYLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKFASI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSFASI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(12).EQ.GINDIV) THEN
        CALL CKFASI(STYLI)
        IF (OKFLAG.EQ.YES) THEN
          FSINDX = STYLI
        END IF
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSFACI
     I                   (COLI)
C
C     + + + PURPOSE + + +
C     set fill area color index individual
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER COLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKCI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GSFACI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKMODE(13).EQ.GINDIV) THEN
        CALL CKCI(COLI)
        IF (OKFLAG.EQ.YES) THEN
          FCOLI = CLRTAB(1,COLI)
        END IF
      ELSE
        WRITE(STDERR,2000)
        EFLAG = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSFAR
     O                  (WKID, FAI,
     I                   INTS, STYLI, COLI)
C
C     + + + PURPOSE + + +
C     set fill area representation
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, FAI, INTS, STYLI, COLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKWKID, CKCI, CKFASI, CKFAI
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Fill area style must be: HOLLOW, HATCHED,',
     #         ' or SOLID.')
C
C     + + + END SPECIFICATIONS + + +
C
      CALL CKWKID(WKID)
      CALL CKCI(COLI)
      CALL CKFASI(STYLI)
      CALL CKFAI(FAI)
C
      IF (INTS.NE.HOLLOW.AND.INTS.NE.HATCHED.AND.INTS.NE.SOLID) THEN
        WRITE(STDERR,2000)
        EFLAG = 1
        FINTSA(WKID,FAI) = HOLLOW
      ELSE
        FINTSA(WKID,FAI) = INTS
      END IF
 
      FSINDA(WKID,FAI) = STYLI
      FCOLIA(WKID,FAI) = COLI
C
      RETURN
      END
C
C
C
      SUBROUTINE   GSFAI
     I                  (INDEX)
C
C     + + + PURPOSE + + +
C     set fill area index bundled
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER INDEX
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + EXTERNALS + + +
      EXTERNAL   CKFAI
C
C     + + + END SPECIFICATIONS + + +
C
C     aspects that are marked individual are not changed.  no warning
C     given
      CALL CKFAI(INDEX)
      FAINDX = INDEX
      IF (WKMODE(11).EQ.GBUNDL) THEN
        FSTYLE = FINTSA(1,INDEX)
      END IF
      IF (WKMODE(12).EQ.GBUNDL) THEN
        FSINDX = FSINDA(1,INDEX)
      END IF
      IF (WKMODE(13).EQ.GBUNDL) THEN
        FCOLI  = CLRTAB(1,FCOLIA(1,INDEX))
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GFA
     I                (N, PX, PY)
C
C     + + + PURPOSE + + +
C     fill area
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER N
      REAL PX(N), PY(N)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER I, NPNT, CLIP, IERR, LOC
      REAL XWTOXV, YWTOYV, XNTOXD, YNTOYD, CLRECT(4)
C
C     + + + EXTERNALS + + +
      EXTERNAL XWTOXV, YWTOYV, XNTOXD, YNTOYD, GFILL, POLY, GCOLN
 
C     + + + INTRINSICS + + +
      INTRINSIC  ABS
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX Work space exceeded in GFA. Space needed=',I5,
     #      ' space available=',I5)
C
C     + + + END SPECIFICATIONS + + +
C
C     set the color
C
      CALL GCOLN(FCOLI)
C
C     convert the world co-ordinates to device co-ordinates using
C     the work space
      IF (N.GT.MXNWRK) THEN
        WRITE(STDERR,2000) N, MXNWRK
      END IF
C
C     implement crude clipping -- fill polygon if it is entirely inside the clipping
C     rectangle. If any part of the polygon is outside the clipping rectangle, then
C     just draw the outline of the clipped polygon using the GPL routine.
      CALL GQCLIP(IERR,CLIP,CLRECT)
      L=0
      IF(CLIP.EQ.GCLIP .AND. IERR.EQ.0) THEN
        DO 200 I=1,N
          CALL INRECT(PX(I),PY(I),CLRECT,L)
          IF(L.NE.0) GO TO 250
200     CONTINUE
250     CONTINUE
      END IF
 
      DO 100 I=1,N
        XWORK(I) = XNTOXD(XWTOXV(PX(I)))
        YWORK(I) = YNTOYD(YWTOYV(PY(I)))
100   CONTINUE
C
C     make sure the shape is closed.
      IF (ABS(XWORK(1)-XWORK(N)).GT.1.0E-30 .OR.
     1   ABS(YWORK(1)-YWORK(N)).GT.1.0E-30) THEN
C       add a point to close the curve
        NPNT = N + 1
        XWORK(NPNT) = XWORK(1)
        YWORK(NPNT) = YWORK(1)
      ELSE
        NPNT = N
      END IF
C
C     set fill style before drawing polygon
      IF (FSTYLE .EQ. 1) THEN
C       solid
        CALL GFILL (4,2,3)
      ELSE IF (FSINDX .EQ. -1) THEN
C       horizontal
        CALL GFILL (1,2,3)
      ELSE IF (FSINDX .EQ. -2) THEN
C       vertical
        CALL GFILL (1,2,4)
      ELSE IF (FSINDX .EQ. -3) THEN
C       diagonal
        CALL GFILL (1,2,2)
      ELSE IF (FSINDX .EQ. -4) THEN
C       right diagonal
        CALL GFILL (1,2,1)
      ELSE IF (FSINDX .EQ. -5) THEN
C       box
        CALL GFILL (2,2,3)
      ELSE IF (FSINDX .EQ. -6) THEN
C       diag box
        CALL GFILL (2,2,1)
      END IF
C     draw polygonal shape using the current color and the width for
C     polylines.  interior style does not redraw the outline.
C
      IF(CLIP.EQ.GNCLIP) THEN
        CALL POLY(NPNT, XWORK, YWORK)
      ELSE IF(L.EQ.0) THEN
        CALL POLY(NPNT, XWORK, YWORK)
      ELSE IF(L.NE.0) THEN
        CALL GPL(N, PX, PY)
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   POLY
     I                  (N, X, Y)
C
C     + + + PURPOSE + + +
C     Draw a polygonal shape in device co-ordinates. Color and
C     line width used as they are.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER N
      REAL X(N), Y(N)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     N      - number of points in polygon
C     X      - array of x values for points being plotted
C     Y      - array of y values for points being plotted
C
C     + + + EXTERNALS + + +
      EXTERNAL   GPOLYA
C
C     + + + END SPECIFICATIONS + + +
C
C     move to the initial point and draw the polygon
      CALL GPOLYA (X,Y,N)
C
      RETURN
      END
C
C
C
      SUBROUTINE   GPREC
     ?                  (IL, IA, RL, RA, NS, LSA, CA, IDIL,
     ?                   ERRIND, IDOL, DR)
C
C     + + + PURPOSE + + +
C     pack data record.  not used for PC but needed to satisfy
C     the linker.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER IL, RL, NS, IDIL, ERRIND, IDOL
c      INTEGER IA(IL), LSA(NS)
c      REAL RA(RL)
c      CHARACTER*(*) CA(NS)
c      CHARACTER*80 DR(IDIL)
 
      INTEGER IA(1), LSA(1)
      REAL RA(1)
      CHARACTER*(*) CA(1)
      CHARACTER*80 DR(1)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + END SPECIFICATIONS + + +
C
C     do nothing
C
      IDOL=1
      RETURN
      END
C
C
C
      SUBROUTINE GSASF
     I                (LASF)
C
C     + + + PURPOSE + + +
C     set aspect source flags.  really a bad name.  aspect is confusing.
C     sets flags for the mode of referencing various attributes.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER LASF(13)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER    I
C
C     + + + END SPECIFICATIONS + + +
C
      DO 100 I=1,13
        WKMODE(I) = LASF(I)
 100  CONTINUE
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQMKSC
     O                   (ERRIND, MSZSF)
C
C     + + + PURPOSE + + +
C     inquire marker size scale factor
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND
      REAL MSZSF
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 8
      ELSE
        ERRIND = 0
      END IF
      MSZSF = MARKSF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQTXFP
     O                   (ERRIND, FONT, PREC)
C
C     + + + PURPOSE + + +
C     inquire text font and precision
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND, FONT, PREC
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 8
      ELSE
        ERRIND = 0
      END IF
      FONT = TXFONT
      PREC = TXPREC
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQWKS
     O                  (WKID, ERRIND, STATE)
C
C     + + + PURPOSE + + +
C     inquire workstation state
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WKID, ERRIND, STATE
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      STATE  = -1
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 7
      ELSE IF (WKID.LT.1 .OR. WKID.GT.MXNWKS) THEN
        ERRIND = 20
      ELSE IF (WSSTAT(WKID).EQ.0) THEN
        ERRIND = 25
      ELSE IF (WSSTAT(WKID).EQ.1) THEN
        STATE  = 0
      ELSE IF (WSSTAT(WKID).EQ.2) THEN
        STATE  = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQOPS
     O                  (OPSTA)
C
C     + + + PURPOSE + + +
C     inquire operating state value
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER OPSTA
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.EQ.0) THEN
C       GKS not opened
        OPSTA = 0
      ELSE IF (GKSOPN.EQ.1) THEN
C       GKS opened
        OPSTA = 1
      ELSE IF (GKSOPN.EQ.2) THEN
C       workstation open
        OPSTA = 2
      ELSE IF (GKSOPN.EQ.3) THEN
C       workstation active
        OPSTA = 3
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQCHH
     O                  (ERRIND, CHH)
C
C     + + + PURPOSE + + +
C     inquire character heigth
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND
      REAL CHH
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 8
      ELSE
        ERRIND = 0
      END IF
      CHH = CHARH
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQCHSP
     O                   (ERRIND, CHSP)
C
C     + + + PURPOSE + + +
C     inquire character spacing
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND
      REAL CHSP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 8
      ELSE
        ERRIND = 0
      END IF
      CHSP = TXSPCF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQCHXP
     O                   (ERRIND, CHXP)
C
C     + + + PURPOSE + + +
C     inquire character expansion factor
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND
      REAL CHXP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 8
      ELSE
        ERRIND = 0
      END IF
      CHXP = TXEXPF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQCF
     O                 (WTYPE, ERRIND, NCOLI, COLA, NPCI)
C
C     + + + PURPOSE + + +
C     inquire color facilities
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER WTYPE, ERRIND, NCOLI, COLA, NPCI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + END SPECIFICATIONS + + +
C
C     wtype meaning not clear. input anyway, ignore for now
 
      IF (GKSOPN.EQ.0) THEN
        ERRIND = 8
      ELSE
        ERRIND = 0
      END IF
C
      NCOLI = 16
      COLA  = 1
      NPCI  = 16
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQTXX
     I                  (WKID, PX, PY, STR,
     O                   ERRIND,CPX,CPY,TXEXPX,TXEXPY)
C
C     + + + PURPOSE + + +
C     INQUIRE TEXT EXTENT- Finds the end point of the given string
C     and the rectangle that encloses the string.  All points to
C     be returned in world co-ordinates.
C
C     + + + DUMMY ARGUMENTS + + +
      CHARACTER*(*) STR
      INTEGER WKID, ERRIND
      REAL PX, PY, CPX, CPY
      REAL TXEXPX(4), TXEXPY(4)
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER    I
      REAL XD, YD, SLEN, STRSIZ, DXDLEN, DYDLEN, DEGRAD,
     #     DXDHGT, DYDHGT, XNTOXD, XWTOXV, YNTOYD, YWTOYV,
     #     XVTOXW, YVTOYW, XDTOXN, YDTOYN
C
C     + + + INTRINSICS + + +
      INTRINSIC   COS, SIN
C
C     + + + EXTERNALS + + +
      EXTERNAL XNTOXD, XWTOXV, YNTOYD, YWTOYV,
     #         XVTOXW, YVTOYW, XDTOXN, YDTOYN, STRSIZ
C
C     + + + DATA INITIALIZAQTIONS + + +
      DATA DEGRAD/0.0174533/
C
C     + + + END SPECIFICATIONS + + +
C
      IF (WKID.NE.1) THEN
        ERRIND = 22
        WKID   = 1
      ELSE IF (WSSTAT(WKID).LT.1) THEN
        ERRIND = 25
      ELSE IF (GKSOPN.LT.3) THEN
        ERRIND = 7
      ELSE
        ERRIND = 0
      END IF
C
C     find the device co-ordinates for the given point
      XD = XNTOXD(XWTOXV(PX))
      YD = YNTOYD(YWTOYV(PY))
C
C     find the string length in device co-ordinates- inches
      IF (STR.EQ.' ') THEN
        SLEN = STRSIZ(CHARHD, 'H')
      ELSE
        SLEN = STRSIZ(CHARHD, STR)
      END IF
C
C     compute the offsets to account for the angle. note the
C     stored angle is in degrees.
      DXDLEN = SLEN*COS(DEGRAD*TXANGL)
      DYDLEN = SLEN*SIN(DEGRAD*TXANGL)
C     now do it for the current character height
      DXDHGT = CHARHD*SIN(DEGRAD*TXANGL)
      DYDHGT = CHARHD*COS(DEGRAD*TXANGL)
C
C     now defind the output values in terms of device co-ordinates
      CPX = XD + DXDLEN
      CPY = YD + DYDLEN
C
C     the test extent rectangle is assumed to go 1/2 character height
C     below the base line.  approx. true for some of the fonts.
C     more exact seting must await defined need.  not critical.
C     usgs graphic package does not currently use these values.
C     therefore skip for now. clear the vectors to avoid garbage.
C
      DO 100 I=1,4
        TXEXPX(I) = 0.0
        TXEXPY(I) = 0.0
 100  CONTINUE
C
C     now convert the device co-ordinates to world co-ordinates
      CPX = XVTOXW(XDTOXN(CPX))
      CPY = YVTOYW(YDTOYN(CPY))
C
      RETURN
      END
C
C
C
      SUBROUTINE   SETASP
     I                   (ASPECT)
C
C     + + + PURPOSE + + +
C     Dummy routine for setting character aspect ratio.
C
C     + + + DUMMY ARGUMENTS + + +
      REAL      ASPECT
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ???
C
C     + + + END SPECIFICATIONS + + +
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQACWK
     I                   (N,
     O                    ERRIND,OL,WKID)
C
C     + + + PURPOSE + + +
C     Inquire number of active work stations.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   N,ERRIND,OL,WKID
C
C     + + + ARGUMENT DEFINITIONS + + +
C     N      - set member requested
C     ERRIND - error indicator
C     OL     - number of active workstations
C     WKID   - nth member of set of active workstations
C
C     + + + END SPECIFICATIONS + + +
C
C     since only one workstation is allowed, just set id to 1
      ERRIND= 0
      OL    = 1
      WKID  = 1
C
      RETURN
      END
C
C
      SUBROUTINE   GQLN
     O                 (ERRIND,L)
C
C     + + + PURPOSE + + +
C     Inquire linetype.
C     Dummy routine added by p. duda.
C     Modified by DWP to return actual line type
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  ERRIND, L
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
 
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      L=0
      DO 1 I=1,5
        IF(GLTYPE.EQ.LINPTR(I)) THEN
          L=I
          RETURN
        END IF
1     CONTINUE
C
      ERRIND=1
      RETURN
      END
C
C
C
      SUBROUTINE   GQLWSC
     O                   (ERRIND,LWIDTH)
C
C     + + + PURPOSE + + +
C     Inquire linewidth scale factor.
C     Dummy routine added by p. duda.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  ERRIND
      REAL     LWIDTH
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      LWIDTH = 1.0
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQPMCI
     O                   (ERRIND,COLI)
C
C     + + + PURPOSE + + +
C     Inquire polymarker color index.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  ERRIND,COLI
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER   I
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GQPMCI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      COLI   = 0
      IF (WKMODE(6).EQ.GINDIV) THEN
        DO 10 I = 1,15
          IF (CLRTAB(1,I).EQ.MCOLOR) THEN
C           found color in table
            COLI = I
          END IF
 10     CONTINUE
      ELSE
        WRITE(STDERR,2000)
        ERRIND = 1
      END IF
 
      RETURN
      END
C
C
C
      SUBROUTINE   GQPLCI
     O                   (ERRIND,COLI)
C
C     + + + PURPOSE + + +
C     Inquire polyline color index.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  ERRIND,COLI
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER   I
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GQPLCI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      COLI   = 0
      IF (WKMODE(6).EQ.GINDIV) THEN
        DO 10 I = 1,15
          IF (CLRTAB(1,I).EQ.LCOLOR) THEN
C           found color in table
            COLI = I
          END IF
 10     CONTINUE
      ELSE
        WRITE(STDERR,2000)
        ERRIND = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQFACI
     O                   (ERRIND,COLI)
C
C     + + + PURPOSE + + +
C     Inquire fill area color index.
C     Dummy routine added by p. duda.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  ERRIND,COLI
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER   I
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GQFACI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      COLI   = 0
      IF (WKMODE(13).EQ.GINDIV) THEN
        DO 10 I = 1,15
          IF (CLRTAB(1,I).EQ.FCOLI) THEN
C           found color in table
            COLI = I
          END IF
 10     CONTINUE
      ELSE
        WRITE(STDERR,2000)
        ERRIND = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE GQFAIS
     O                 (ERRIND,INTS)
C
C     + + + PURPOSE + + +
C     Inquire fill area interior style.
C     Dummy routine added by p. duda.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER  ERRIND,INTS
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      INTS   = 1
C
      RETURN
      END
 
C***************************************************************************
C
C   The following routines originally in GKSINTX.FOR were modified by DWP:
C
C   GQNT   -- was dummy routine. now it retrieves window and viewport dimensions
C   GQCNTN -- was dummy routine. now it retrieves current transformation number
C   GQWKC  -- was dummy routine. now returns workstation type
C
C***************************************************************************
C
C
      SUBROUTINE   GQWKC
     I                   (WKID,
     O                    ERRIND,CONID,WTYPE)
C
C     + + + PURPOSE + + +
C     inquire workstation connection and type
C     modified by DWP. now returns the workstation type.
C
C     + + + DUMMY ARGUMENTS + ++
      INTEGER   WKID,ERRIND,CONID,WTYPE
C     + + + COMMON BLOCK
      INCLUDE 'LKAGKS.INC'
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - workstation identifier
C     ERRIND - error indicator
C     CONID  - connection identifier
C     WTYPE  - workstation type
C
C      + + + END SPECIFICATIONS + + +
C
C       WRITE(99,*) 'GKS:GQWKC:'
       WTYPE=MONVEC(WKID)
C
       RETURN
       END
C
C
C
      SUBROUTINE   GQCNTN
     O                   (ERRIND,CNTR)
C
C     + + + PURPOSE + + +
C     inquire current normalization transformation number.
C     This routine was modified by DWP. It returns the
C     current normalization transformation. A variable named
C     CURNTN was added to common in LKAGKS.INC.
C
C     + + + DUMMY ARGUMENTS + ++
      INTEGER   ERRIND,CNTR
C     + + + COMMON BLOCK
      INCLUDE 'LKAGKS.INC'
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRIND - error indicator
C     CNTR   - current transformation number
C
C      + + + END SPECIFICATIONS + + +
C
       ERRIND=0
       CNTR=CURNTN
C
       RETURN
       END
C
C
C
      SUBROUTINE   GQTXCI
     O                   (ERRIND,COLI)
C
C     + + + PURPOSE + + +
C     inquire text color index 

C     + + + DUMMY ARGUMENTS + ++
      INTEGER   ERRIND,COLI
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRIND - error indicator
C     COLI   - text color index
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
      INCLUDE 'gksprm.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER   I
C
C     + + + OUTPUT FORMATS + + +
 2000 FORMAT(/,' ERR:XXX In GQTXCI working mode is:bundled.')
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      COLI   = 0
      IF (WKMODE(10).EQ.GINDIV) THEN
        DO 10 I = 1,15
          IF (CLRTAB(1,I).EQ.TXCOLI) THEN
C           found color in table
            COLI = I
          END IF
 10     CONTINUE
      ELSE
        WRITE(STDERR,2000)
        ERRIND = 1
      END IF
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQMK
     O                 (ERRIND,MTYP)
C
C     + + + PURPOSE + + +
C     inquire marker type
C
C     + + + DUMMY ARGUMENTS + ++
      INTEGER   ERRIND,MTYP
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRIND - error indicator
C     MTYP   - marker type
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      INTEGER   I
C
C      + + + END SPECIFICATIONS + + +
C
       MTYP  = -2
       ERRIND= 0
C
       I= -9
 10    CONTINUE
         IF (MRKPTR(I) .EQ. MTYPE) THEN
           MTYP= I
         ELSE
           I= I+ 1
         END IF
       IF (MTYP.EQ.-2 .AND. I.LE.5) GO TO 10
C
       IF (MTYP.EQ.-2) THEN
C        not found
         I= 0
         MTYP= MRKPTR(I)
       END IF
C
       WRITE(99,*) 'GKS:GQMK:',MTYP,MRKPTR(I),ERRIND
C
       RETURN
       END
C
C
C
      SUBROUTINE   GQCHUP
     O                   (ERRIND,CHUX,CHUY)
C
C     + + + PURPOSE + + +
C     inquire character up vector
C
C     + + + DUMMY ARGUMENTS + ++
      INTEGER   ERRIND
      REAL      CHUX,CHUY
C
      INCLUDE 'lkagks.inc'
C
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRIND - error indicator
C     CHUX   - character up vector (WC)
C     CHUY   - character up vector (WC)
C
C      + + + END SPECIFICATIONS + + +
C
       ERRIND=0
       CHUX=CHARUX
       CHUY=CHARUY
C       WRITE(99,*) 'GKS:GQCHUP:'
C
       RETURN
       END
C
C
C
      SUBROUTINE   GQTXAL
     O                   (ERRIND,TXALH,TXALV)
C
C     + + + PURPOSE + + +
C     inquire text alignment
C
C     + + + DUMMY ARGUMENTS + ++
      INTEGER   ERRIND,TXALH,TXALV
C
      INCLUDE 'lkagks.inc'
C
C
C     + + + ARGUMENT DEFINITIONS + + +
C     ERRIND - error indicator
C     TXALH  - text alignment horizontal (GAHNOR,GALEFT,GACENT,GARITE)
C     TXALV  - text alignment vertical (GAVNOR,GATOP,GACAP,GAHALF,
C                                       GABASE,GABOTTT)
C
C      + + + END SPECIFICATIONS + + +
C
C       WRITE(99,*) 'GKS:GQTXAL:'
       ERRIND=0
       TXALH=TXALGH
       TXALV=TXALGV
C
       RETURN
       END
C
C
C
      SUBROUTINE   GQCR
     I                 (WKID,COLI,TYPE,ERRIND,CR,CG,CB)
C
C     + + + PURPOSE + + +
C     inquire colour representation (DOES NOT WORK)
C
C
      INCLUDE 'lkagks.inc'

C     + + + DUMMY ARGUMENTS + + +
      INTEGER   WKID,COLI,TYPE,ERRIND
      REAL      CR,CG,CB
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - workstation identifier
C     COLI   - color index
C     TYPE   - type of returned values (GSET,GREALI)
C     ERRIND - error indicator
C     CR     - red intensity
C     CG     - green intensity
C     CB     - blue intensity
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND = 0
      CR= CLRRED(WKID,COLI)
      CG= CLRGRN(WKID,COLI)
      CB= CLRBLU(WKID,COLI)
C
      RETURN
      END
C
C
C
C
C
      SUBROUTINE   GUWK
     I                 (WKID,REGFL)
C
C     + + + PURPOSE + + +
C     update workstation (DOES NOT WORK)
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   WKID,REGFL
C
C     + + + ARGUMENT DEFINITIONS + + +
C     WKID   - workstation identifier
C     REGFL  - update regeneration flag (GPOSTP, GPERFO)
C
C     + + + END SPECIFICATIONS + + +
C
      WRITE(99,*) 'GKS:GUWK:',WKID,REGFL
C
      RETURN
      END
C
C
C
      SUBROUTINE   GQNT
     I                 (NTNR,
     O                  ERRIND,WINDOW,VIEWPT)
C
C     + + + PURPOSE + + +
C     inquire normalization transformation
C     This routine was modified by DWP
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER   NTNR,ERRIND
      REAL      WINDOW(4),VIEWPT(4)
C
      INCLUDE 'lkagks.inc'
C
C     + + + ARGUMENT DEFINITIONS + + +
C     NTNR   - normalization transformation number
C     ERRIND - error indicator
C     WINDOW - window limits in world coords (XMIN,XMAX,YMIN,YMAX)
C     VIEWPT - viewprt lim in normalized dev coord(XMIN,XMAX,YMIN,YMAX)
C
C     + + + END SPECICIFICATIONS + + +
C
C      WRITE (99,*) 'GKS:GQNT :'
      ERRIND=0
      WINDOW(1)=XWMINV(NTNR)
      WINDOW(2)=XWMAXV(NTNR)
      WINDOW(3)=YWMINV(NTNR)
      WINDOW(4)=YWMAXV(NTNR)
      VIEWPT(1)=XVMINV(NTNR)
      VIEWPT(2)=XVMAXV(NTNR)
      VIEWPT(3)=YVMINV(NTNR)
      VIEWPT(4)=YVMAXV(NTNR)
C
      RETURN
      END
C
 
 
C**********************************************************************
C    The following new GKS routines were added to deal with clipping:
C
C    GQCLIP  -- retrieves clipping on/off indicator and the current
C               clipping rectangle
C
C*********************************************************************
 
      SUBROUTINE   GQCLIP
     O                   (ERRIND,CLIP,CLRECT)
C
C     + + + PURPOSE + + +
C     Inquire clipping indicator and clipping rectangle
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER ERRIND,CLIP
      REAL CLRECT(4)
C
C     + + + PARAMETERS + + +
      INCLUDE 'gksprm.inc'
C
C     + + + COMMON BLOCKS + + +
      INCLUDE 'lkagks.inc'
C
C     + + + LOCAL VARIABLES + + +
      REAL VIEWPT(4)
      INTEGER TNR
C
C     + + + END SPECIFICATIONS + + +
C
      ERRIND=0
C     get the clipping indicator
      CLIP=CLIPIT
C
C     find out the current normalization transformation number
      CALL GQCNTN(IERR,TNR)
      IF(IERR.NE.0) THEN
        ERRIND=1
        RETURN
      END IF
C
C     get the clipping rectangle for the current transformation
      CALL GQNT(TNR,IERR,CLRECT,VIEWPT)
      IF(IERR.NE.0) ERRIND=2
      RETURN
      END
 
C**********************************************************************
C    The following computational routines were added to implement polyline
C    clipping and crude text, marker, and polygon fill clipping.
C
C    INRECT   -- determine if a point is within clipping rectangle
C    XYINT    -- find the intersection point of a line segment with
C                the clipping rectangle
C    VSIDE    -- find potential intersection points along vertical
C                sides of the clipping rectangle
C    HSIDE    -- find potential intersection points along horizontal
C                sides of the clipping rectangle
C**********************************************************************
 
      SUBROUTINE   INRECT
     I                   (X,Y,RECT,
     O                    LOC)
C
C     + + + PURPOSE + + +
C     Find out if a point is inside a rectangle. Returns a value
C     in LOC that is 0 if point is inside the rectangle. If point
C     is outside the rectangle, the value of LOC is non-zero and
C     indicates the sector outside the rectangle that includes the
C     point. Providing the sector number helps in searching for
C     the intersection point. The sectors are defined as:
C
C                      |           |
C               6      |     4     |     8
C                      |           |
C          ------------*************-----------
C                      *           *
C               1      * Rectangle *     2
C                      *     0     *
C          ------------*************-----------
C                      |           |
C               5      |     3     |     7
C                      |           |
C
C
C     + + + DUMMY ARGUMENTS + + +
      REAL X, Y, RECT(4)
      INTEGER LOC
C
C     + + + LOCAL VARIABLES + + +
      INTEGER LX, LY
C
C     + + + END SPECICIFICATIONS + + +
C
      LX=0
      IF(X.LT.RECT(1)) THEN
        LX= -1
      ELSE IF(X.GT.RECT(2)) THEN
        LX= 1
      END IF
C
      LY=0
      IF(Y.LT.RECT(3)) THEN
        LY= -1
      ELSE IF(Y.GT.RECT(4)) THEN
        LY= 1
      END IF
C
      IF(LY.EQ.-1) THEN
        IF(LX.EQ.-1) THEN
          LOC=5
        ELSE IF(LX.EQ.0) THEN
          LOC=3
        ELSE IF(LX.EQ.1) THEN
          LOC=7
        END IF
      ELSE IF(LY.EQ.0) THEN
        IF(LX.EQ.-1) THEN
          LOC=1
        ELSE IF(LX.EQ.0) THEN
          LOC=0
        ELSE IF(LX.EQ.1) THEN
          LOC=2
        END IF
      ELSE IF(LY.EQ.1) THEN
        IF(LX.EQ.-1) THEN
          LOC=6
        ELSE IF(LX.EQ.0) THEN
          LOC=4
        ELSE IF(LX.EQ.1) THEN
          LOC=8
        END IF
      END IF
      RETURN
      END
 
      SUBROUTINE   XYINT
     I                  (LOC1,LOC2,RECT,X,Y,
     O                   XNEW,YNEW,ERRIND)
C
C     + + + PURPOSE + + +
C     This routine finds the intersection point of a line segment with the
C     clipping rectangle. It calls routines VSIDE and HSIDE, which compute
C     potential intersection points along the vertical and horizontal side,
C     respectively.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER LOC1, LOC2, ERRIND
      REAL X(2),Y(2),RECT(4),XNEW(2),YNEW(2)
C
C     + + + LOCAL VARIABLES + + +
      REAL XIV, XIH, XI, YI
      INTEGER L, IERR1, IERR2
 
C     + + + END SPECIFICATIONS + + +
C
      XMIN=RECT(1)
      XMAX=RECT(2)
      YMIN=RECT(3)
      YMAX=RECT(4)
C
      DO 1 I=1,2
      XNEW(I)=X(I)
      YNEW(I)=Y(I)
1     CONTINUE
C
      ERRIND=0
C
      IF(LOC1.EQ.0 .AND. LOC2.EQ.0) THEN
        ERRIND=1
        RETURN
      ELSE IF(LOC1.GT.8 .OR. LOC2.GT.8) THEN
        ERRIND=1
        RETURN
      ELSE IF(LOC1.NE.0 .AND. LOC2.NE.0) THEN
        IF(X(1).LE.XMIN .AND. X(2).LE.XMIN) THEN
          ERRIND=1
          RETURN
        ELSE IF(X(1).GE.XMAX .AND. X(2).GE.XMAX) THEN
          ERRIND=1
          RETURN
        ELSE IF(Y(1).LE.YMIN .AND. Y(2).LE.YMIN) THEN
          ERRIND=1
          RETURN
        ELSE IF(Y(1).GE.YMAX .AND. Y(2).GE.YMAX) THEN
          ERRIND=1
          RETURN
        ELSE
          IPT=0
          CALL VSIDE(XMIN,YMIN,YMAX,X,Y,XI,YI,IERR)
          IF(IERR.EQ.0) THEN
            IPT=IPT+1
            XNEW(IPT)=XI
            YNEW(IPT)=YI
          END IF
          CALL HSIDE(YMIN,XMIN,XMAX,X,Y,XI,YI,IERR)
          IF(IERR.EQ.0) THEN
            IPT=IPT+1
            XNEW(IPT)=XI
            YNEW(IPT)=YI
            IF(IPT.EQ.2) RETURN
          END IF
          CALL VSIDE(XMAX,YMIN,YMAX,X,Y,XI,YI,IERR)
          IF(IERR.EQ.0) THEN
            IPT=IPT+1
            XNEW(IPT)=XI
            YNEW(IPT)=YI
            IF(IPT.EQ.2) RETURN
          END IF
          CALL HSIDE(YMAX,XMIN,XMAX,X,Y,XI,YI,IERR)
          IF(IERR.EQ.0) THEN
            IPT=IPT+1
            XNEW(IPT)=XI
            YNEW(IPT)=YI
            IF(IPT.EQ.2) RETURN
          END IF
          ERRIND=1
          RETURN
        END IF
      ELSE
C      If it gets this far, then one point is in and the other is out. Compute the
C      intersection point.
        L=0
        IF(LOC1.NE.0) L=LOC1
        IF(LOC2.NE.0) L=LOC2
C
        IF(L.EQ.1) THEN
          CALL VSIDE(XMIN,YMIN,YMAX,X,Y,XI,YI,ERRIND)
        ELSE IF(L.EQ.2) THEN
          CALL VSIDE(XMAX,YMIN,YMAX,X,Y,XI,YI,ERRIND)
        ELSE IF(L.EQ.3) THEN
          CALL HSIDE(YMIN,XMIN,XMAX,X,Y,XI,YI,ERRIND)
        ELSE IF(L.EQ.4) THEN
          CALL HSIDE(YMAX,XMIN,XMAX,X,Y,XI,YI,ERRIND)
        ELSE IF(L.EQ.5) THEN
          CALL VSIDE(XMIN,YMIN,YMAX,X,Y,XIV,YIV,IERR1)
          CALL HSIDE(YMIN,XMIN,XMAX,X,Y,XIH,YIH,IERR2)
          IF(IERR1.EQ.0) THEN
            ERRIND=0
            XI=XIV
            YI=YIV
          ELSE IF(IERR2.EQ.0) THEN
            ERRIND=0
            XI=XIH
            YI=YIH
          ELSE
            ERRIND=1
          END IF
        ELSE IF(L.EQ.6) THEN
          CALL VSIDE(XMIN,YMIN,YMAX,X,Y,XIV,YIV,IERR1)
          CALL HSIDE(YMAX,XMIN,XMAX,X,Y,XIH,YIH,IERR2)
          IF(IERR1.EQ.0) THEN
            ERRIND=0
            XI=XIV
            YI=YIV
          ELSE IF(IERR2.EQ.0) THEN
            ERRIND=0
            XI=XIH
            YI=YIH
          ELSE
            ERRIND=1
          END IF
        ELSE IF(L.EQ.7) THEN
          CALL VSIDE(XMAX,YMIN,YMAX,X,Y,XIV,YIV,IERR1)
          CALL HSIDE(YMIN,XMIN,XMAX,X,Y,XIH,YIH,IERR2)
          IF(IERR1.EQ.0) THEN
            ERRIND=0
            XI=XIV
            YI=YIV
          ELSE IF(IERR2.EQ.0) THEN
            ERRIND=0
            XI=XIH
            YI=YIH
          ELSE
            ERRIND=1
          END IF
        ELSE IF(L.EQ.8) THEN
          CALL VSIDE(XMAX,YMIN,YMAX,X,Y,XIV,YIV,IERR1)
          CALL HSIDE(YMAX,XMIN,XMAX,X,Y,XIH,YIH,IERR2)
          IF(IERR1.EQ.0) THEN
            ERRIND=0
            XI=XIV
            YI=YIV
          ELSE IF(IERR2.EQ.0) THEN
            ERRIND=0
            XI=XIH
            YI=YIH
          ELSE
            ERRIND=1
          END IF
        END IF
C
        IF(LOC1.EQ.0) THEN
          XNEW(2)=XI
          YNEW(2)=YI
        ELSE IF(LOC2.EQ.0) THEN
          XNEW(1)=XI
          YNEW(1)=YI
        END IF
C
      END IF
C
      RETURN
      END
 
      SUBROUTINE   VSIDE
     I                  (XS,YMIN,YMAX,X,Y,
     O                   XI,YI,IERR)
C
C     + + + PURPOSE + + +
C     This routine finds the intersection point of a line segment with one of
C     the vertical sides of the clipping rectangle (i.e. the left or right sides).
C
C     + + + DUMMY ARGUMENTS + + +
      REAL XS, YMIN, YMAX, X(2), Y(2)
C
C     + + + LOCAL VARIABLES + + +
      INTEGER IERR
      REAL XI, YI
C
C     + + + END SPECIFICATIONS + + +
C
      DX=X(2)-X(1)
      DY=Y(2)-Y(1)
C
C     Check for vertical line segment. If so, it cannot intersect side
      IF(DX.EQ.0.0) THEN
        IERR=1
        RETURN
      END IF
C
C     Check for horizontal line segment. If intersection is within
C     range YMIN to YMAX, set intersection point. Otherwise, set error
C     flag.
      IF(DY.EQ.0.0) THEN
        IF(Y(1).LE.YMAX .AND. Y(1).GE.YMIN) THEN
          IERR=0
          XI=XS
          YI=Y(1)
        ELSE
          IERR=1
        END IF
      RETURN
      END IF
C
C     Compute intersection point for lines that are not horizontal or
C     vertical.
      A=DY/DX
      YY=A*XS - A*X(1) + Y(1)
      IF(YY.LE.YMAX .AND. YY.GE.YMIN) THEN
        IERR=0
        XI=XS
        YI=YY
      ELSE
        IERR=1
      END IF
      RETURN
      END
 
      SUBROUTINE   HSIDE
     I                  (YS,XMIN,XMAX,X,Y,
     O                   XI,YI,IERR)
C
C     + + + PURPOSE + + +
C     This routine finds the intersection point of a line segment with one of
C     the horizontal sides of the clipping rectangle (i.e. the top or bottom).
C
C     + + + DUMMY ARGUMENTS + + +
      REAL YS, XMIN, XMAX, X(2), Y(2)
C
C     + + + LOCAL VARIABLES + + +
      INTEGER IERR
      REAL XI, YI
C
C     + + + END SPECIFICATIONS + + +
C
      DX=X(2)-X(1)
      DY=Y(2)-Y(1)
C
C     Check for horizontal line segment. If so, it cannot intersect side
      IF(DY.EQ.0.0) THEN
        IERR=1
        RETURN
      END IF
C
C     Check for vertical line segment. If intersection is within
C     range XMIN to XMAX, set intersection point. Otherwise, set error
C     flag.
      IF(DX.EQ.0.0) THEN
        IF(X(1).LE.XMAX .AND. X(1).GE.XMIN) THEN
          IERR=0
          XI=X(1)
          YI=YS
        ELSE
          IERR=1
        END IF
      RETURN
      END IF
C
C     Compute intersection point for lines that are not horizontal or
C     vertical.
      A=DY/DX
      XX=X(1) + YS/A - Y(1)/A
      IF(XX.LE.XMAX .AND. XX.GE.XMIN) THEN
        IERR=0
        XI=XX
        YI=YS
      ELSE
        IERR=1
      END IF
C
      RETURN
      END
 
 
