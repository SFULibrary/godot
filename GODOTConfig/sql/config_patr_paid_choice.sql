CREATE TABLE config_patr_paid_choice (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,

	rank		INTEGER NOT NULL,

        payment_method  VARCHAR(512),
        input_box       BOOLEAN    
);
