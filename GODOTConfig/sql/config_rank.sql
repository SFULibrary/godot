CREATE TABLE config_rank (
	id		SERIAL PRIMARY KEY,
	site		INTEGER NOT NULL,
	rank		INTEGER NOT NULL,
	rank_site	VARCHAR(512),
	display_group	INTEGER,
	search_group	INTEGER,
	auto_req	BOOLEAN
);


