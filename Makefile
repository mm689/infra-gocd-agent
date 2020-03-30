
run: need-aws-credentials
	./tasks build


need-env-%:
	@if [ -z "$($*)" ]; then \
		echo "Missing environment variable: $*" >&2; \
		exit 1; \
	fi

need-aws-credentials: need-env-AWS_ACCESS_KEY_ID need-env-AWS_SECRET_ACCESS_KEY
