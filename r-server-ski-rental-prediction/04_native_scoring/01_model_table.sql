USE SkiRentals;

DROP TABLE IF EXISTS rental_models;
GO
CREATE TABLE rental_models (
	model_name VARCHAR(30) NOT NULL DEFAULT('default model'),
	lang VARCHAR(30),
	model VARBINARY(MAX),
	native_model VARBINARY(MAX),
	PRIMARY KEY (model_name, lang)
);
GO
