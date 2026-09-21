def doGet(request, session):
	params = request.get('params', {})

	# Simulator CSV download (customize the tag path for your project)
	# simulatorCsv = params.get('simulatorCsv', None)
	# if simulatorCsv is not None:
	# 	csv_qv = system.tag.readBlocking(['[default]YourPath/To/DeviceCSV'])[0]
	# 	if csv_qv.quality.isGood() and csv_qv.value:
	# 		response = request['servletResponse']
	# 		response.setContentType('text/csv')
	# 		response.setHeader('Content-Disposition', 'attachment; filename="sim_program.csv"')
	# 		writer = response.getWriter()
	# 		writer.print(csv_qv.value)
	# 		writer.flush()
	# 		return
	# 	return {'json': {'error': 'No CSV generated.'}}

	# Browse mode: list tag providers or browse a path
	browse = params.get('browse', None)
	if browse is not None:
		# Handle Java String[] from query params
		from java.lang.reflect import Array
		if hasattr(browse, '__len__') and not isinstance(browse, (str, unicode)):
			browse = Array.get(browse, 0)

		if browse == '' or browse == 'providers':
			# List top-level tag providers
			results = system.tag.browse('')
			providers = []
			for r in results.getResults():
				providers.append(str(r))
			return {'json': {'providers': providers}}
		else:
			# Browse a specific path
			results = system.tag.browse(browse)
			tags = []
			for r in results.getResults():
				tags.append(str(r))
			return {'json': {'path': browse, 'tags': tags}}

	return {'json': {
		'endpoint': 'testing/tags',
		'description': 'Read/write tags for E2E testing',
		'usage': {
			'GET': {
				'browse': '?browse=providers or ?browse=[default]Path',
				'simulatorCsv': '?simulatorCsv=true - download device simulator CSV program'
			},
			'POST': {
				'writes': [{'path': '[default]Tag/Path', 'value': 'someValue'}],
				'reads': ['[default]Tag/Path']
			}
		}
	}}