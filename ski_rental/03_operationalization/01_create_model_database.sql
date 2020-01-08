DROP TABLE IF EXISTS rental_rx_models;
GO
CREATE TABLE rental_models (
	model_name VARCHAR(30) NOT NULL DEFAULT('default model') PRIMARY KEY,
	model VARBINARY(MAX) NOT NULL
);

GO