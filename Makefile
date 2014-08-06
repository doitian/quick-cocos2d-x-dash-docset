generate:
	./generate.rb
	open quick-cocos2d-x.docset

package:
	tar --exclude='.DS_Store' -cvzf quick-cocos2d-x.tgz quick-cocos2d-x.docset

.PHONY: generate package
