CREATE TABLE config_ill_req_form_limit (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,

	rank		INTEGER NOT NULL,

        patron_type     VARCHAR(512),
        message         VARCHAR(512)    
);
