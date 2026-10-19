import FocusCore
import XCTest

final class SitesListTests: XCTestCase {
    func testDomainsSkipCommentsBlanksAndInvalidLines() {
        let list = SitesList(text: "# comment\nreddit.com\n\n  x.com  \nbad entry.com\n")
        XCTAssertEqual(list.domains, ["reddit.com", "x.com"])
    }

    func testAddNormalizesAndRejectsDuplicates() {
        var list = SitesList(text: "reddit.com\n")
        XCTAssertTrue(list.add("https://www.YouTube.com/watch?v=1"))
        XCTAssertFalse(list.add("www.reddit.com"))
        XCTAssertFalse(list.add("not a domain"))
        XCTAssertEqual(list.text, "reddit.com\nyoutube.com\n")
    }

    func testRemoveKeepsCommentsAndOrder() {
        var list = SitesList(text: "# social\nreddit.com\nx.com\n# news\nnews.ycombinator.com\n")
        list.remove("x.com")
        XCTAssertEqual(list.text, "# social\nreddit.com\n# news\nnews.ycombinator.com\n")
    }

    func testNormalize() {
        XCTAssertEqual(SitesList.normalize("news.ycombinator.com:443/item"), "news.ycombinator.com")
        XCTAssertNil(SitesList.normalize("localhost"))
        XCTAssertNil(SitesList.normalize(""))
    }
}
