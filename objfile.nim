import logging
import strutils
import tables
import mesh

proc tof32(s: string): float32 = s.parseFloat.float32

proc loadObj*(path: string): MeshData =
  var
    p = newSeq[array[3, float32]]()
    n = newSeq[array[3, float32]]()
    uv = newSeq[array[2, float32]]()
    map = initTable[string, uint32]()

  result = newMeshData()
  
  for line in lines(path):
    var fields = line.split
    if len(fields) < 1:
      continue
    case fields[0]:
    of "v":
      p.add([fields[1].tof32, fields[2].tof32, fields[3].tof32])
    of "vt":
      uv.add([fields[1].tof32, fields[2].tof32])
    of "vn":
      n.add([fields[1].tof32, fields[2].tof32, fields[3].tof32])
    of "f":
      for v in fields[1..3]:
        let i = v.split('/')
        if not map.hasKey(v):
          map[v] = len(map).uint32
          result.vertices.add(Vertex(
            position: p[i[0].parseInt - 1],
            uv: uv[i[1].parseInt - 1],
            normal: n[i[2].parseInt - 1],
          ))

        result.indices.add(map[v])
    else:
      discard