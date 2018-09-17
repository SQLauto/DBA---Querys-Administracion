DECLARE @FechaDesde DATETIME,
		@FechaHasta DATETIME,
		@IdTipoMultimedia INT,
		@PageIndex INT,
		@PageSize INT

SELECT  @FechaDesde = '20180719',
		@FechaHasta = '20180720',
		@IdTipoMultimedia = 1,
		@PageIndex = 2,
		@PageSize = 10

SELECT Id,IdTipoMultimedia,Url  
FROM Multimedia WHERE FechaAlta>=@FechaDesde 
	AND FechaAlta<=@FechaHasta 
	AND IdTipoMultimedia = @IdTipoMultimedia
ORDER BY ROW_NUMBER() OVER (ORDER BY FechaAlta DESC) OFFSET (@PageIndex-1)*@PageSize ROWS FETCH FIRST @PageSize ROWS ONLY;