define ->

  Vector = 

    det : ([x1,y1],[x2,y2]) ->
      x1*y2 - x2*y1

    norm : ([x,y]) ->
      Math.sqrt(x*x + y*y)

    angleRad : (v1,v2) ->
      Math.acos(Vector.scalarProduct(v1,v2) / Vector.norm(v1) / Vector.norm (v2)) * 
        (if Vector.det(v1,v2) > 0 then -1 else 1)

    angleDeg : (v1,v2) ->
      Vector.radToDeg Vector.angleRad v1, v2

    angle: (u,v) ->
      Vector.angleDeg u, v

    radToDeg : (angle) ->
      angle / Math.PI * 180

    degToRad : (angle) ->
      angle / 180 * Math.PI

    make_rotation_matrix : (angleInDeg) ->
      angleInRad = Vector.degToRad angleInDeg
      [
        [ Math.cos(angleInRad) , -Math.sin(angleInRad) ]
        [ Math.sin(angleInRad) ,  Math.cos(angleInRad) ]
      ]

    product_matrix_vector : ( [[x1, y1], [x2, y2]], [x0, y0] ) ->
      [x1*x0 + y1*y0, x2*x0 + y2*y0]
      
    rotate: (vector, angle) ->
      Vector.product_matrix_vector Vector.make_rotation_matrix(angle), vector

    subtract: ([x1,y1],[x2,y2]) ->
      [x1-x2, y1-y2]

    add: ([x1,y1],[x2,y2]) ->
      [x1+x2, y1+y2]

    multiply: (v,a) ->
      [v[0]*a, v[1]*a]

    scalarProduct: ([x1,y1],[x2,y2]) ->
      x1*x2 + y1*y2

    plainProduct: ([x1,y1],[x2,y2]) ->
      [x1*x2, y1*y2]

    normalize: (v) ->
      Vector.multiply v, 1/Vector.norm(v)

    toCssSize: (v) ->
      width: v[0]
      height: v[1]

    fromCssPosition: (pos) ->
      [pos.left, pos.top]
