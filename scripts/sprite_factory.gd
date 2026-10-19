class_name SpriteFactory
extends RefCounted
## All textures are rasterized locally using Godot Image. No external art.

static func ellipse(img: Image, center: Vector2, radius: Vector2, color: Color) -> void:
    for y in range(maxi(0, int(center.y - radius.y - 1)), mini(img.get_height(), int(center.y + radius.y + 2))):
        for x in range(maxi(0, int(center.x - radius.x - 1)), mini(img.get_width(), int(center.x + radius.x + 2))):
            var distance := Vector2((x + 0.5 - center.x) / radius.x, (y + 0.5 - center.y) / radius.y).length()
            var coverage := clampf((1.0 - distance) * minf(radius.x, radius.y) + 0.5, 0.0, 1.0)
            if coverage > 0.0:
                var source := color
                source.a *= coverage
                img.set_pixel(x, y, img.get_pixel(x, y).blend(source))

static func rect(img: Image, bounds: Rect2i, color: Color) -> void:
    img.fill_rect(bounds.intersection(Rect2i(0, 0, img.get_width(), img.get_height())), color)

static func pet(expression: String = "idle") -> Texture2D:
    var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    # Feet, wings, warm egg-shaped body, soft belly, and sprout.
    ellipse(img, Vector2(98, 223), Vector2(26, 12), Color("c77943"))
    ellipse(img, Vector2(160, 223), Vector2(26, 12), Color("c77943"))
    ellipse(img, Vector2(53, 158), Vector2(25, 39), Color("e2a44e"))
    ellipse(img, Vector2(203, 158), Vector2(25, 39), Color("e2a44e"))
    ellipse(img, Vector2(128, 137), Vector2(83, 93), Color("e9af58"))
    ellipse(img, Vector2(128, 132), Vector2(78, 88), Color("f8cf78"))
    ellipse(img, Vector2(119, 181), Vector2(55, 41), Color("ffe7ac"))
    ellipse(img, Vector2(103, 71), Vector2(33, 16), Color("ffde95"))
    ellipse(img, Vector2(128, 39), Vector2(4, 18), Color("568871"))
    ellipse(img, Vector2(112, 28), Vector2(19, 10), Color("8da97b"))
    ellipse(img, Vector2(141, 20), Vector2(18, 11), Color("668d6a"))
    ellipse(img, Vector2(77, 151), Vector2(17, 10), Color("ed9b7c"))
    ellipse(img, Vector2(179, 151), Vector2(17, 10), Color("ed9b7c"))
    var ink := Color("584a40")
    if expression == "happy" or expression == "pet":
        for eye_x in [99.0, 157.0]:
            ellipse(img, Vector2(eye_x, 130), Vector2(13, 10), ink)
            ellipse(img, Vector2(eye_x, 135), Vector2(13, 10), Color("f8cf78"))
    elif expression == "blink":
        ellipse(img, Vector2(99, 132), Vector2(10, 3), ink)
        ellipse(img, Vector2(157, 132), Vector2(10, 3), ink)
    else:
        for eye_x in [99.0, 157.0]:
            ellipse(img, Vector2(eye_x, 130), Vector2(7, 11), ink)
            ellipse(img, Vector2(eye_x - 2, 126), Vector2(2, 3), Color("fff9e7"))
    ellipse(img, Vector2(128, 148), Vector2(10, 7), Color("d98342"))
    if expression == "happy":
        ellipse(img, Vector2(128, 162), Vector2(10, 8), ink)
        ellipse(img, Vector2(128, 167), Vector2(6, 3), Color("efb19b"))
    return ImageTexture.create_from_image(img)

static func plant() -> Texture2D:
    var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    rect(img, Rect2i(123, 62, 9, 130), Color("557f68"))
    for leaf in [Vector3(94, 90, 0), Vector3(160, 64, 0), Vector3(84, 139, 0), Vector3(163, 119, 0), Vector3(125, 46, 0)]:
        ellipse(img, Vector2(leaf.x, leaf.y), Vector2(34, 21), Color("7f9f7b"))
        ellipse(img, Vector2(leaf.x - 5, leaf.y - 5), Vector2(24, 12), Color("99b48b"))
    rect(img, Rect2i(89, 178, 78, 49), Color("ca8d72"))
    ellipse(img, Vector2(128, 225), Vector2(39, 11), Color("ca8d72"))
    ellipse(img, Vector2(128, 178), Vector2(46, 12), Color("e4ac8a"))
    ellipse(img, Vector2(128, 177), Vector2(34, 6), Color("756452"))
    return ImageTexture.create_from_image(img)

static func cushion() -> Texture2D:
    var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    ellipse(img, Vector2(128, 193), Vector2(103, 39), Color("839b90"))
    ellipse(img, Vector2(128, 183), Vector2(103, 34), Color("b7c9b5"))
    ellipse(img, Vector2(128, 178), Vector2(84, 24), Color("c9d8bf"))
    for x in [68, 98, 128, 158, 188]:
        ellipse(img, Vector2(x, 182), Vector2(2, 2), Color("91aa94"))
    return ImageTexture.create_from_image(img)

static func heart() -> Texture2D:
    var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    var pink := Color("e9a08f")
    ellipse(img, Vector2(22, 23), Vector2(15, 15), pink)
    ellipse(img, Vector2(42, 23), Vector2(15, 15), pink)
    for y in range(23, 55):
        var half_width := int((55 - y) * 0.87)
        rect(img, Rect2i(32 - half_width, y, half_width * 2, 1), pink)
    return ImageTexture.create_from_image(img)

static func floor_texture() -> Texture2D:
    var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    img.fill(Color("e4decd"))
    rect(img, Rect2i(0, 0, 128, 128), Color("eee7d7"))
    rect(img, Rect2i(128, 128, 128, 128), Color("eee7d7"))
    return ImageTexture.create_from_image(img)

static func rug() -> Texture2D:
    var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    ellipse(img, Vector2(128, 128), Vector2(126, 126), Color("b8b896"))
    ellipse(img, Vector2(128, 128), Vector2(120, 120), Color("d5d0ad"))
    ellipse(img, Vector2(128, 128), Vector2(108, 108), Color("e2d9b5"))
    return ImageTexture.create_from_image(img)

static func shadow() -> Texture2D:
    var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    ellipse(img, Vector2(64, 64), Vector2(60, 45), Color(0.24, 0.27, 0.20, 0.16))
    return ImageTexture.create_from_image(img)
