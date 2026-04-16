import json
import math

with open("./test/test.json", "r") as f:
  data = json.load(f).get("song")

  output = []
  bpm = data.get("bpm", 100.0)
  speed = data.get("speed", 1.0)

  output.append("[BpmChanges]")
  output.append(f"0={bpm}")
  output.append("")

  output.append("[VelocityChanges]")
  output.append(f"0={speed}")
  output.append("")

  notedata = data.get("notes", [])
  strumlineNotes = {}
  totalnotes = 0

  curbpm = bpm

  #eventTime = 0.0
  for sec in notedata:
    if sec.get("changeBPM") and sec.get("bpm", bpm) != bpm:
      curbpm = sec.get("bpm", bpm)
    for note in sec.get("sectionNotes", []):
      notetype = note[3] if len(note) > 3 else "normal"
      beat = float(note[0]) * curbpm / 60000.0
      if len(note) > 2:
        length = float(note[2]) * curbpm / 60000.0
      else:
        length = 0.0
      lane = note[1]

      strumidx = lane // 4
      if strumidx not in strumlineNotes:
        strumlineNotes[strumidx] = []
      strumlineNotes[strumidx].append((beat, lane % 4, notetype, length))
      totalnotes += 1
  
  for i in strumlineNotes:
    strumlineNotes[i].sort(key=lambda x: x[0])
    print(len(strumlineNotes[i]))
  
  notesPerLine = 5
  for i in sorted(strumlineNotes):
    output.append(f"[Strumline:{i}]")
    output.append("skin=default")
    output.append("keyCount=4")
    #output.append("notes=")

    batch = []
    for time, lane, ntype, length in strumlineNotes[i]:
      coolNote = f"{time},{lane},{ntype},{length}"
      batch.append(coolNote)
      if len(batch) == notesPerLine:
        output.append("notes=" + "|".join(batch))
        batch = []
    if batch:
      output.append("notes=" + "|".join(batch))
    output.append("")

    print(f"total notes {totalnotes}")
  
    with open("./test.kfc", 'w') as f:
        f.write("\n".join(output))
