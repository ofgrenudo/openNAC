.PHONY: docs

# Builds and serves docs/ at http://localhost:4000 with live reload, using the
# official jekyll/jekyll image so no local Ruby install is needed. Gems are
# cached in the jekyll-bundle volume across runs.
docs:
	docker run --rm -it \
		-p 4000:4000 \
		-v "$(CURDIR)/docs:/srv/jekyll" \
		-v jekyll-bundle:/usr/local/bundle \
		jekyll/jekyll:latest \
		sh -c "bundle install && bundle exec jekyll serve --host 0.0.0.0 --livereload"
