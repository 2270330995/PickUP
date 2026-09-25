-- Vehicles are now identified primarily by a mandatory label, since organizers
-- adding a person often don't know the exact make/model on hand. Make and model
-- become optional.
UPDATE vehicles
SET label = btrim(concat_ws(' ', make, model))
WHERE label IS NULL OR btrim(label) = '';

UPDATE vehicles
SET label = 'Vehicle'
WHERE btrim(label) = '';

ALTER TABLE vehicles ALTER COLUMN label SET NOT NULL;
ALTER TABLE vehicles ALTER COLUMN make DROP NOT NULL;
ALTER TABLE vehicles ALTER COLUMN model DROP NOT NULL;
