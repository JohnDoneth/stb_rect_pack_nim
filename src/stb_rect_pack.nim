import stb_rect_pack/stb_rect_pack

{.compile: "src/stb_rect_pack/pack.c".}

type
  Heuristic* {.pure.} = enum
    hSkylineDefault, 
    ## Use whatever the default heuristic is.
    hSkylineBLSortHeight,
    hSkylineBFSortHeight

  RectPackContext* = ref object
    raw: ptr stbrp_context
    nodes: ptr stbrp_node
    node_len: cint

  Rect* = object
    ## This structure retains the original C types to avoid
    ## a copy for the sake of using Nim integer types.
    id*: cint ## reserved for your use
    width*: cint
    height*: cint
    x*: cint
    y*: cint
    was_packed*: bool

proc finalizeRectPackContext*(context: RectPackContext) =
  ## Frees the resources associated with a RectPackContext.
  ## 
  ## This is only exposed for testing! You should not need to call this manually.
  if context.raw != nil:
    dealloc(context.raw)
    context.raw = nil

  if context.nodes != nil:
    dealloc(context.nodes)
    context.nodes = nil

proc toC(h: Heuristic): cint =
  case h:
    of hSkylineDefault: STBRP_HEURISTIC_Skyline_default
    of hSkylineBLSortHeight: STBRP_HEURISTIC_Skyline_BL_sortHeight
    of hSkylineBFSortHeight: STBRP_HEURISTIC_Skyline_BF_sortHeight

proc newRectPackContext*(width, height, nodes: int): RectPackContext =
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
  ##  Note: to guarantee best results: make sure 'num_nodes' >= 'width'
  var context: RectPackContext
  new(context, finalizeRectPackContext)
  context.raw = cast[ptr stbrp_context](alloc(stbrp_context.sizeof()))
  context.nodes = cast[ptr stbrp_node](alloc(stbrp_node.sizeof() * nodes))
  context.node_len = nodes.cint

  stbrp_init_target(
    context.raw, 
    width.cint, 
    height.cint,
    context.nodes,
    context.node_len
  )

  context

proc setHeuristic*(context: RectPackContext, heuristic: Heuristic): RectPackContext =
  ##  Optionally select which packing heuristic the library should use. Different
  ##  heuristics will produce better/worse results for different data sets.
  ##  If you call init again, this will be reset to the default.
  stbrp_setup_heuristic(context.raw, heuristic.toC())
  context

proc packRects*(context: RectPackContext, rects: openArray[Rect]): bool =
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
  stbrp_pack_rects(
    context.raw,
    cast[ptr stbrp_rect](rects[0].unsafeAddr),
    rects.len.cint
  ).bool