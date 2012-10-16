CREATE TABLE wip.bergamo_1_mappings (
    id serial primary key,
    dirname character varying,
    original_object_id integer,
    digital_object_id integer,
    digital_collection_id integer
);

GRANT ALL ON wip.bergamo_1_mappings TO rails;

INSERT INTO wip.bergamo_1_mappings (id, dirname, original_object_id, digital_object_id, digital_collection_id) VALUES (1, '1659_Egisto-L', 102, 146, 2);
INSERT INTO wip.bergamo_1_mappings (id, dirname, original_object_id, digital_object_id, digital_collection_id) VALUES (2, '1659_Irbeno-L', 103, 154, 2);

