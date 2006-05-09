CREATE TABLE config_request_non_journal (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,

	rank		INTEGER NOT NULL,

	request_site	VARCHAR(512),
        type            VARCHAR(512)    
);

