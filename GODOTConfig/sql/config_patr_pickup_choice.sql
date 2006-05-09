CREATE TABLE config_patr_pickup_choice (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,

	rank		INTEGER NOT NULL,

        location        VARCHAR(512)
);
