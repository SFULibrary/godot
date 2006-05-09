CREATE TABLE site_chains (
	id		SERIAL PRIMARY KEY,
	site		INTEGER,
	rank		INTEGER,
	chain		INTEGER
);

CREATE INDEX site_chains_site_idx on site_chains(site);

