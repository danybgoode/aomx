-- Raw numerator and denominator are part of an immutable published reading.
-- A rounded percentage can stay equal when the underlying cohort changes.
alter table alpha_private.publication_days
  add column if not exists numerator integer,
  add column if not exists denominator integer,
  add column if not exists reading_hash text;
