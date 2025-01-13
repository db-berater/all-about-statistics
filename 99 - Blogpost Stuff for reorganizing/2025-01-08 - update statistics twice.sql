	SELECT	AllocUnitName,
			Operation,
			COUNT_BIG(*)	AS	affected_rows
	FROM	dbo.get_transaction_info(N'update_customers')
	WHERE	AllocUnitName IS NOT NULL
	GROUP BY
			AllocUnitName,
			Operation;