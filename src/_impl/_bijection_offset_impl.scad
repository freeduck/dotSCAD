use <../__comm__/__lines_from.scad>;
use <../__comm__/__line_intersection.scad>;
    
function _bijection_outward_edge_normal(edge) =     
    let(
        v = edge[1] - edge[0],
        nv = v / norm(v)
    )
    [nv.y, -nv.x];

function _bijection_offset_edge(edge, dxy) = edge + [dxy, dxy];
    
function _bijection__bijection_offset_edges(edges, d) = 
    [ 
        for(edge = edges)
        _bijection_offset_edge(edge, _bijection_outward_edge_normal(edge) * d)
    ];

function _bijection_offset_impl(pts, d, epsilon) = 
    let(
        es = __lines_from(pts, true), 
        offset_es = _bijection__bijection_offset_edges(es, d),
        leng_minus_one = len(offset_es) - 1,
        last_p = __line_intersection2(offset_es[leng_minus_one], offset_es[0], epsilon)
    )
    [
        // p == p to avoid [nan, nan], because [nan, nan] != [nan, nan]
        if(last_p != [] && last_p == last_p) last_p,
        each [
            for(i = 0; i < leng_minus_one; i = i + 1)
            let(
                this_edge = offset_es[i],
                next_edge = offset_es[i + 1],
                p = __line_intersection2(this_edge, next_edge, epsilon)
            )
            assert(p != [] && p == p, "bijection_offset failed. Parallel or conincident edges found")
            p
        ]
    ];
    