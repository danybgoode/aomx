# CDMX geography source and rights record · 2026-10-22

This wave uses factual names and administrative references. Its 28×28 La Roma battlefield is independently authored and stylized. No external boundary geometry, coordinates, imagery, map tiles or site text was imported.

| Source | Checked fact / candidate | Terms decision |
| --- | --- | --- |
| [INEGI AGEM catalog API for entity 09](https://gaia.inegi.org.mx/wscatgeo/v2/mgem/09), read 2026-10-22 | Returned 16 records, codes 09002–09017 and their names. Those name/code facts appear in `game/content/geography/cdmx.v1.json`. | No API response file or geometry is shipped. Keep the source attribution in the registry. Review the applicable INEGI reuse terms before importing any geometry or larger data extract. |
| [CDMX alcaldía boundary dataset](https://www.datos.cdmx.gob.mx/es/dataset/alcaldias), checked 2026-10-22 | Candidate source for administrative polygons from the INEGI 2020 Marco Geoestadístico. | The portal displays CC-BY-4.0-ESP. Exact resource and upstream INEGI terms still need review; **do not import** in this wave. Portal warns that datasets can change retroactively. |
| [ADIP colonia catalog](https://www.datos.cdmx.gob.mx/es/dataset/catalogo-de-colonias-datos-abiertos), checked 2026-10-22 | Candidate colonia polygon and name dataset. | The portal displays CC-BY-4.0-ESP. Exact resource terms and version still need review; **do not import** in this wave. |
| [CDMX tourism venue listing: Fuente de Cibeles](https://mexicocity.cdmx.gob.mx/venues/cibeles/), checked 2026-10-22 | Lists Plaza Villa de Madrid, Roma Norte, Cuauhtémoc. The game uses the factual place/parent relationship. | No page text, coordinates, imagery or venue geometry is copied. Display `Fuente de Cibeles` only as a factual place name; the in-game objective remains a stylized artwork and grid anchor. |

## Reference and authored space

- Stable alcaldía IDs use the INEGI five-digit `cvegeo` prefixed by `alc_`. The current catalog skips 09001 and contains 09002–09017; this is not a claim that IDs are sequential forever.
- `col_roma_norte` and `place_fuente_cibeles` are the two focused place records. The city venue listing supports their parent chain. No colonia polygon, precise coordinate or physical footprint is asserted.
- `territory_roma_norte_cibeles` is a **fictional playable territory**. The `la_roma` grid has no coordinate reference system or projection. The objective anchor `[9,9]` is an authored tile within the existing district and is not a transformation of a real-world coordinate.
- `full-map.jpg` remains art direction; it cannot supply borders or source placement. A later campaign or map wave must record its source version, projection, transforms, attribution and review before importing geography.

## Owner portrayal check

The visible setup calls the battlefield stylized, names Roma Norte/Cibeles and explains both win routes in plain language. Any disputed visible place label or depiction returns to the owner under [Ways of Working](../../Roadmap/WAYS-OF-WORKING.md#escalate-dont-guess). Human comprehension and downloaded-build owner QA remain open until performed.
