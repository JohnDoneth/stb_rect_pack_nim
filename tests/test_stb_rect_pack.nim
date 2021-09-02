import unittest
import stb_rect_pack

suite "newRectPackContext":
    test "creates a RectPackContext":
        check newRectPackContext(100, 100, 100) != nil
    
suite "packRects":
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
    