
EXECUTE sp_execute_external_script
@language=N'R'
,@script = N'
	packagematrix <- installed.packages();
	Name <- packagematrix[,1];
	Version <- packagematrix[,3];
	OutputDataSet <- data.frame(Name, Version);'
, @input_data_1 = N''
WITH RESULT SETS (
	(
		PackageName nvarchar(250), 
		PackageVersion nvarchar(max) 
	)
)