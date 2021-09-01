SHELL := /bin/bash
STACKNAME?= aws-servicecatalog-example
S3_BUCKET?= OVERRIDE_THIS
S3_PREFIX?= local

clean:
	rm -rf ./product_cleanup/package
	rm -f product_cleanup/template.out.yml
	rm -f cfn_portfolio.out.yml
	
validate:
	aws cloudformation validate-template --template-body file://product_cleanup/template.yml --output text
	aws cloudformation validate-template --template-body file://cfn_product1.yml --output text
	aws cloudformation validate-template --template-body file://cfn_portfolio.yml --output text

build: validate clean 
	cd product_cleanup \
	&& mkdir package \
	&& find . ! -regex '.*/package' ! -regex '.' -exec cp -r '{}' package \;\
	&& pip3 install -r requirements.txt -t ./package

package: build
	aws cloudformation package \
		--template-file product_cleanup/template.yml \
		--s3-bucket $(S3_BUCKET) \
		--s3-prefix $(S3_PREFIX) \
		--output-template-file product_cleanup/template.out.yml
	aws cloudformation package \
		--template-file cfn_portfolio.yml \
		--s3-bucket $(S3_BUCKET) \
		--s3-prefix $(S3_PREFIX) \
		--output-template-file cfn_portfolio.out.yml

deploy: package
	aws s3 cp cfn_product1.yml s3://${S3_BUCKET}/${S3_PREFIX}/cfn_product1.yml \
	&& aws cloudformation deploy \
		--stack-name $(STACKNAME) \
		--template-file cfn_portfolio.out.yml \
		--parameter-overrides 'Product1Template=https://s3.us-east-1.amazonaws.com/${S3_BUCKET}/${S3_PREFIX}/cfn_product1.yml' \
		--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	&& aws iam add-user-to-group \
		--user-name $$( aws sts get-caller-identity | jq -r .Arn | cut -d "/" -f2 ) \
		--group-name $$(aws cloudformation describe-stacks --stack-name $(STACKNAME) | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PortfolioGroupName") | .OutputValue')

provision:
	aws servicecatalog provision-product \
		--product-name Product1 \
		--provisioning-artifact-name 1.0 \
		--provisioned-product-name provisioned 

terminate:
	aws servicecatalog terminate-provisioned-product \
		--provisioned-product-name provisioned 	

destroy: 
	aws iam remove-user-from-group \
		--user-name $$( aws sts get-caller-identity | jq -r .Arn | cut -d "/" -f2 ) \
		--group-name $$(aws cloudformation describe-stacks --stack-name $(STACKNAME) | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PortfolioGroupName") | .OutputValue') \
	&& aws cloudformation delete-stack \
		--stack-name $(STACKNAME) \
	&& aws cloudformation wait stack-delete-complete \
		--stack-name $(STACKNAME)
