CREATE OR REPLACE FUNCTION drape_sampled(line geometry) RETURNS geometry AS $$
DECLARE                                                                                                      line3d geometry;
BEGIN
    RAISE NOTICE 'draping';
    WITH linemeasure AS
      -- Add a measure dimension to extract steps
      (SELECT ST_AddMeasure(line, 0, ST_Length(line)) as linem,
              generate_series(0, ST_Length(line)::int, 500) as i),
    points2d AS
      -- TODO does this
      (SELECT ST_GeometryN(ST_LocateAlong(linem, i), 1) AS geom FROM linemeasure),
    cells AS
      -- Get DEM elevation for each
      (SELECT p.geom AS geom, ST_Value(ned.rast, 1, p.geom) AS val
      FROM ned, points2d p
      WHERE ST_Intersects(ned.rast, p.geom)),
      -- Instantiate 3D points
    points3d AS
      (SELECT ST_SetSRID(ST_MakePoint(ST_X(geom), ST_Y(geom), val), ST_SRID(line)) AS geom FROM cells)
    SELECT ST_MakeLine(geom) INTO line3d FROM points3d;
    RETURN line3d;
END;
$$ LANGUAGE plpgsql;
