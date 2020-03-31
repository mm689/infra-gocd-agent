
build-and-deploy: need-sibling-directory-infra-gocd
	@$(MAKE) build-and-push
	@$(MAKE) deploy

build build-and-push: need-aws-credentials
	./tasks build
	@$(MAKE) tag-as-latest

build-local:
	./tasks build_local

deploy deploy-to-production: need-sibling-directory-infra-gocd
	@# Try to just update the agent. If that fails, assume we must deploy fully.
	cd ../infra-gocd && export GOCD_ENV=production &&\
	(make provision-agent || make deploy)

tag-as-latest: ./image/imagerc
	. $< && docker tag $$KUDU_DOCKER_IMAGE_NAME:$$KUDU_DOCKER_IMAGE_TAG $$KUDU_DOCKER_IMAGE_NAME:latest \
	&& docker push $$KUDU_DOCKER_IMAGE_NAME:latest

need-sibling-directory-%:
	@if [ ! -d ../$* ]; then echo "Expected sibling directory: $*" >&2 && exit 1; fi

need-env-%:
	@if [ -z "$($*)" ]; then echo "Missing environment variable: $*" >&2 && exit 1; fi

need-aws-credentials: need-env-AWS_ACCESS_KEY_ID need-env-AWS_SECRET_ACCESS_KEY
