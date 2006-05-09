CREATE TABLE config_ill_account (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,

	rank		INTEGER NOT NULL,

        account_site    VARCHAR(512),
        number          VARCHAR(512)    
);
