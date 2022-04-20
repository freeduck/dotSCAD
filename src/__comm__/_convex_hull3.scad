use <../util/sorted.scad>;
use <../matrix/m_replace.scad>;

function normal(pts, f) = cross(pts[f[1]] - pts[f[0]], pts[f[2]] - pts[f[0]]);

function _fst_v1(pts, leng, i) =
    i == leng || (pts[i] - pts[0]) != [0, 0, 0] ? i : _fst_v1(pts, leng, i + 1);
  
function _fst_v2(pts, leng, v1, i) = 
    i == leng || cross(pts[v1] - pts[0], pts[i] - pts[0]) != [0, 0, 0] ? i : _fst_v2(pts, leng, v1, i + 1);

function _fst_v3(pts, leng, n, d, i) =
    i == leng ? [i, d] :
    let(nd = n * (pts[i] - pts[0]))
    nd != 0 ? [i, nd] : _fst_v3(pts, leng, n, nd, i + 1);

function next_vis(i, pts, cur_faces, cur_faces_leng, next, vis, j = 0) = 
    j == cur_faces_leng ? [next, vis] :
    let(
        f = cur_faces[j],
        d = (pts[f[0]] - pts[i]) * normal(pts, f),
        nx = d >= 0 ? [each next, f] : next,
        s = sign(d),
        vis1 = m_replace(vis, f[1], f[0], s),
        vis2 = m_replace(vis1, f[2], f[1], s),
        vis3 = m_replace(vis2, f[0], f[2], s)
    )
    next_vis(i, pts, cur_faces, cur_faces_leng, nx, vis3, j + 1);
    
function next2(i, cur_faces, cur_faces_leng, vis, next, j = 0) = 
    j == cur_faces_leng ? next : 
    let(
        f = cur_faces[j],
        a = f[0],
        b = f[1],
        c = f[2],
        nx1 = vis[a][b] < 0 && vis[a][b] != vis[b][a] ? 
            [each next, [a, b, i]] : next,
        nx2 = vis[b][c] < 0 && vis[b][c] != vis[c][b] ? 
            [each nx1, [b, c, i]] : nx1,        
        nx3 = vis[c][a] < 0 && vis[c][a] != vis[a][c] ? 
            [each nx2, [c, a, i]] : nx2                    
    )
    next2(i, cur_faces, cur_faces_leng, vis, nx3, j + 1);

function _all_faces(v0, v1, v2, v3, pts, pts_leng, vis, cur_faces, i = 0) =
    i == pts_leng ? cur_faces :
    let(
        vis_faces = i == v0 || i == v1 || i == v2 || i == v3 ? [vis, cur_faces] :
        let(
            cur_faces_leng = len(cur_faces),
            nv = next_vis(i, pts, cur_faces, cur_faces_leng, [], vis),
            nx1 = nv[0],
            vis1 = nv[1],
            nx2 = next2(i, cur_faces, cur_faces_leng, vis1, nx1)
        ) 
        [vis1, nx2]
    )
    _all_faces(v0, v1, v2, v3, pts, pts_leng, vis_faces[0], vis_faces[1], i + 1);

function _convex_hull3(pts) = 
    let(
        sorted_pts = sorted(pts),
        leng = len(sorted_pts),
        v0 = 0,
        v1 =  _fst_v1(sorted_pts, leng, v0 + 1),
        v2 = assert(v1 < leng, "common points") 
             _fst_v2(sorted_pts, leng, v1, v1 + 1),
        n = assert(v2 < leng, "collinear points") 
            cross(sorted_pts[v1] - sorted_pts[v0], sorted_pts[v2] - sorted_pts[v0]),
        v3_d = _fst_v3(sorted_pts, leng, n, 0, v2 + 1),
        v3 = v3_d[0],
        d = assert(v3 < leng, "coplanar points")
            v3_d[1],
        fst_tetrahedron = d > 0 ? [
                [v1, v0, v2],
                [v0, v1, v3],
                [v1, v2, v3],
                [v2, v0, v3]
            ] 
            : 
            [
                [v0, v1, v2],
                [v1, v0, v3],
                [v2, v1, v3],
                [v0, v2, v3]
            ],
        zeros = [for(j = [0:leng - 1]) 0],
        init_vis = [for(i = [0:leng - 1]) zeros],
        faces = _all_faces(v0, v1, v2, v3, sorted_pts, leng, init_vis, fst_tetrahedron), // counter-clockwise
        reversed = [
            for(face = faces)      // OpenSCAD requires clockwise.
            [face[2], face[1], face[0]]
        ]
    )
    [
        sorted_pts,
        reversed   
    ];