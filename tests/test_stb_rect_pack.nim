import 
    unittest, 
    stb_rect_pack, 
    sequtils, 
    sugar,
    random

suite "newRectPackContext":
    test "creates a RectPackContext":
        check newRectPackContext(100, 100, 100) != nil
    
suite "finalizeRectPackContext":
    test "frees the resources of a RectPackContext":
        finalizeRectPackContext(newRectPackContext(100, 100, 100))

    test "does not double free the resources of a RectPackContext":
        let context = newRectPackContext(100, 100, 100)
        finalizeRectPackContext(context)
        finalizeRectPackContext(context)

suite "setHeuristic":
    test "sets the heuristic to use by the RectPackContext and returns the context":
        let context = newRectPackContext(100, 100, 100)
        check context == context.setHeuristic(Heuristic.hSkylineDefault)

suite "packRects":
    test "can be called in succession":
        let 
            context = newRectPackContext(10, 30, 10)
            rects1 = @[Rect(width: 10, height: 10)]
            rects2 = @[Rect(width: 10, height: 10)]
            rects3 = @[Rect(width: 10, height: 10)]

        check context.packRects(rects1)
        check context.packRects(rects2)
        check context.packRects(rects3);

        check rects1 == @[Rect(
            width: 10,
            height: 10,
            x: 0,
            y: 0,
            was_packed: true,
        )]

        check rects2 == @[Rect(
            width: 10,
            height: 10,
            x: 0,
            y: 10,
            was_packed: true,
        )]

        check rects3 == @[Rect(
            width: 10,
            height: 10,
            x: 0,
            y: 20,
            was_packed: true,
        )]

    test "returns false when the rectangles do not fit":
        let context = newRectPackContext(100, 100, 100)

        let rects = @[
            # Try packing too large of a rectangle.
            Rect(
                width: 110,
                height: 110,
                x: 0,
                y: 0,
            ),
        ]

        check context.packRects(rects) == false # Should fail as the rectangle is too large.

    test "packs rectangles":
        let context = newRectPackContext(10, 30, 10)

        let rects = @[
            Rect(
                width: 10,
                height: 10,
                x: 0,
                y: 0,
            ), 
            Rect(
                width: 10,
                height: 10,
                x: 0,
                y: 0,
            ), 
            Rect(
                width: 10,
                height: 10,
                x: 0,
                y: 0,
            ),
        ]

        check context.packRects(rects)

        check rects == @[
            Rect(
                width: 10,
                height: 10,
                x: 0,
                y: 0,
                was_packed: true,
            ), 
            Rect(
                width: 10,
                height: 10,
                x: 0,
                y: 10,
                was_packed: true,
            ), 
            Rect(
                width: 10,
                height: 10,
                x: 0,
                y: 20,
                was_packed: true,
            ),
        ]
    
    test "stress test - skyline default":
        let context = newRectPackContext(1000, 1000, 100)

        let rects = toSeq(1..100).map(_ => 
            Rect(
                width: rand(1..6).cint,
                height: rand(1..6).cint
            )
        )

        check context.packRects(rects)

    test "stress test - skyline best fit":
        let context = newRectPackContext(1000, 1000, 100).setHeuristic(Heuristic.hSkylineBFSortHeight)

        let rects = toSeq(1..100).map(_ => 
            Rect(
                width: rand(1..6).cint,
                height: rand(1..6).cint
            )
        )

        check context.packRects(rects)