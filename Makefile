DIRCONTENTS := chapters
DIRSCRIPTS := scripts
DIRBUILDS := output
DIRWORK := $(shell pwd -P)

.PHONY: all clean assets rules html pdf epub
.PHONY: check check-rules check-rules-duplicates check-rules-incorrects
.PHONY: next-rule-id

all: clean html pdf epub rules
clean:
	rm -rf $(DIRBUILDS);

check: check-rules
check-rules: check-rules-duplicates check-rules-incorrects
check-rules-duplicates:
	@DUPLICATED="$$(grep -rohE "\[#[0-9]+]" $(DIRCONTENTS) | sort |uniq -d)"; \
	if [ -n "$${DUPLICATED}" ]; then \
	    echo "Duplicated Rule IDs: $$(echo "$${DUPLICATED}" | tr -d '\n')"; \
	    echo "Please make sure the Rule ID anchors are unique"; \
	    exit 1; \
	fi;

check-rules-incorrects:
	@INCORRECT="$$(grep -rnE "(\[[0-9]+\]|\[ +#?[0-9]+ +\])" $(DIRCONTENTS))"; \
	if [ -n "$${INCORRECT}" ]; then \
	    echo -e "Incorrect Rule IDs:\n $${INCORRECT}"; \
	    echo "Please make sure that the Rule ID anchors conform to '\[#[0-9]+\]'"; \
	    exit 1; \
	fi;

next-rule-id:
	@IFS=$$'\r\n' GLOBIGNORE='*' command eval \
	"RULE_IDS=($$(grep -rh "^.*\[#[0-9]\{1,5\}.*$$" $(DIRCONTENTS) | sort -r))"; \
	echo $$(($$(echo $${RULE_IDS[0]} | tr -d '\[' | tr -d '\]' | tr -d '#') + 1));

assets:
	mkdir -p $(DIRBUILDS);
	cp -r assets $(DIRBUILDS)/assets;
	cp -r models/* $(DIRBUILDS);

rules: check-rules
	$(DIRSCRIPTS)/generate-rules-json.sh  | \
	  jq -s '{rules: . | sort}' | tee $(DIRBUILDS)/rules >$(DIRBUILDS)/rules.json;

html: check assets
	asciidoctor --failure-level=WARN -D $(DIRBUILDS) index.adoc;

pdf: check
	asciidoctor-pdf -D $(DIRBUILDS) index.adoc;
	mv -f $(DIRBUILDS)/index.pdf $(DIRBUILDS)/api_style_guide.pdf;

epub: check
	asciidoctor-epub3 --failure-level=ERROR -D $(DIRBUILDS) index.adoc;
	mv -f $(DIRBUILDS)/index.epub $(DIRBUILDS)/api_style_guide.epub;
