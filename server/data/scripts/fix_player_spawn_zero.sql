-- Personagens com pos 0,0,0 (criação MyAAC) — teleportar para templo da town_id
-- Coordenadas do realmap.otbm (movement dreamer tower / guides)

UPDATE players SET posx = 32369, posy = 32241, posz = 7
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND town_id = 2 AND deletion = 0;

UPDATE players SET posx = 32649, posy = 31925, posz = 11
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND town_id = 3 AND deletion = 0;

UPDATE players SET posx = 32957, posy = 32076, posz = 7
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND town_id = 4 AND deletion = 0;

UPDATE players SET posx = 32360, posy = 31782, posz = 7
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND town_id = 5 AND deletion = 0;

UPDATE players SET posx = 33194, posy = 32853, posz = 8
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND town_id = 9 AND deletion = 0;

UPDATE players SET posx = 33217, posy = 31814, posz = 8
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND town_id = 11 AND deletion = 0;

-- town_id inválido ou 0 → Thais
UPDATE players SET posx = 32369, posy = 32241, posz = 7, town_id = 2
  WHERE posx = 0 AND posy = 0 AND posz = 0 AND (town_id = 0 OR town_id IS NULL) AND deletion = 0;
