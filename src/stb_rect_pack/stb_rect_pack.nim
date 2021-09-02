##  stb_rect_pack.h - v1.01 - public domain - rectangle packing
##  Sean Barrett 2014
##
##  Useful for e.g. packing rectangular textures into an atlas.
##  Does not do rotation.
##
##  Before #including,
##
##     #define STB_RECT_PACK_IMPLEMENTATION
##
##  in the file that you want to have the implementation.
##
##  Not necessarily the awesomest packing method, but better than
##  the totally naive one in stb_truetype (which is primarily what
##  this is meant to replace).
##
##  Has only had a few tests run, may have issues.
##
##  More docs to come.
##
##  No memory allocations; uses qsort() and assert() from stdlib.
##  Can override those by defining STBRP_SORT and assert.
##
##  This library currently uses the Skyline Bottom-Left algorithm.
##
##  Please note: better rectangle packers are welcome! Please
##  implement them to the same API, but with a different init
##  function.
##
##  Credits
##
##   Library
##     Sean Barrett
##   Minor features
##     Martins Mozeiko
##     github:IntellectualKitty
##
##   Bugfixes / warning fixes
##     Jeremy Jaussaud
##     Fabian Giesen
##
##  Version history:
##
##      1.01  (2021-07-11)  always use large rect mode, expose STBRP__MAXVAL in public section
##      1.00  (2019-02-25)  avoid small space waste; gracefully fail too-wide rectangles
##      0.99  (2019-02-07)  warning fixes
##      0.11  (2017-03-03)  return packing success/fail result
##      0.10  (2016-10-25)  remove cast-away-const to avoid warnings
##      0.09  (2016-08-27)  fix compiler warnings
##      0.08  (2015-09-13)  really fix bug with empty rects (w=0 or h=0)
##      0.07  (2015-09-13)  fix bug with empty rects (w=0 or h=0)
##      0.06  (2015-04-15)  added STBRP_SORT to allow replacing qsort
##      0.05:  added assert to allow replacing assert
##      0.04:  fixed minor bug in STBRP_LARGE_RECTS support
##      0.01:  initial release
##
##  LICENSE
##
##    See end of file for license information.
## ////////////////////////////////////////////////////////////////////////////
##
##        INCLUDE SECTION
##

const
  STB_RECT_PACK_VERSION* = 1

when defined(STBRP_STATIC):
  const
    STBRP_DEF* = `static`
else:
  discard
type
  stbrp_coord* = cint

const
  STBRP_MAXVAL* = 0x7fffffff

## ////////////////////////////////////////////////////////////////////////////
##
##  the details of the following structures don't matter to you, but they must
##  be visible so you can handle the memory allocations for them

type
  stbrp_node* {.bycopy.} = object
    x*: stbrp_coord
    y*: stbrp_coord
    next*: ptr stbrp_node

  stbrp_context* {.bycopy.} = object
    width*: cint
    height*: cint
    align*: cint
    init_mode*: cint
    heuristic*: cint
    num_nodes*: cint
    active_head*: ptr stbrp_node
    free_head*: ptr stbrp_node
    extra*: array[2, stbrp_node] ##  we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'

  stbrp_rect* {.bycopy.} = object
    id*: cint                  ##  reserved for your use:
    ##  input:
    w*: stbrp_coord
    h*: stbrp_coord            ##  output:
    x*: stbrp_coord
    y*: stbrp_coord
    was_packed*: cint          ##  non-zero if valid packing


##  Mostly for internal use, but this is the maximum supported coordinate value.

proc stbrp_pack_rects*(context: ptr stbrp_context; rects: ptr stbrp_rect;
                      num_rects: cint): cint {.importc.}
##  Assign packed locations to rectangles. The rectangles are of type
##  'stbrp_rect' defined below, stored in the array 'rects', and there
##  are 'num_rects' many of them.
##
##  Rectangles which are successfully packed have the 'was_packed' flag
##  set to a non-zero value and 'x' and 'y' store the minimum location
##  on each axis (i.e. bottom-left in cartesian coordinates, top-left
##  if you imagine y increasing downwards). Rectangles which do not fit
##  have the 'was_packed' flag set to 0.
##
##  You should not try to access the 'rects' array from another thread
##  while this function is running, as the function temporarily reorders
##  the array while it executes.
##
##  To pack into another rectangle, you need to call stbrp_init_target
##  again. To continue packing into the same rectangle, you can call
##  this function again. Calling this multiple times with multiple rect
##  arrays will probably produce worse packing results than calling it
##  a single time with the full rectangle array, but the option is
##  available.
##
##  The function returns 1 if all of the rectangles were successfully
##  packed and 0 otherwise.



##  16 bytes, nominally

proc stbrp_init_target*(context: ptr stbrp_context; width: cint; height: cint;
                       nodes: ptr stbrp_node; num_nodes: cint) {.importc.}
##  Initialize a rectangle packer to:
##     pack a rectangle that is 'width' by 'height' in dimensions
##     using temporary storage provided by the array 'nodes', which is 'num_nodes' long
##
##  You must call this function every time you start packing into a new target.
##
##  There is no "shutdown" function. The 'nodes' memory must stay valid for
##  the following stbrp_pack_rects() call (or calls), but can be freed after
##  the call (or calls) finish.
##
##  Note: to guarantee best results, either:
##        1. make sure 'num_nodes' >= 'width'
##    or  2. call stbrp_allow_out_of_mem() defined below with 'allow_out_of_mem = 1'
##
##  If you don't do either of the above things, widths will be quantized to multiples
##  of small integers to guarantee the algorithm doesn't run out of temporary storage.
##
##  If you do #2, then the non-quantized algorithm will be used, but the algorithm
##  may run out of temporary storage and be unable to pack some rectangles.

proc stbrp_setup_allow_out_of_mem*(context: ptr stbrp_context;
                                  allow_out_of_mem: cint) {.importc.}
##  Optionally call this function after init but before doing any packing to
##  change the handling of the out-of-temp-memory scenario, described above.
##  If you call init again, this will be reset to the default (false).

proc stbrp_setup_heuristic*(context: ptr stbrp_context; heuristic: cint) {.importc.}
##  Optionally select which packing heuristic the library should use. Different
##  heuristics will produce better/worse results for different data sets.
##  If you call init again, this will be reset to the default.

const
  STBRP_HEURISTIC_Skyline_default* = 0
  STBRP_HEURISTIC_Skyline_BL_sortHeight* = STBRP_HEURISTIC_Skyline_default
  STBRP_HEURISTIC_Skyline_BF_sortHeight* = 1
  
