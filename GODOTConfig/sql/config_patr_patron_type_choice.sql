CREATE TABLE config_patr_patron_type_choice (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,

	rank		INTEGER NOT NULL,

        type            VARCHAR(512)    
);

