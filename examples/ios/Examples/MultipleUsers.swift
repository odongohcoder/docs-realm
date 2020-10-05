import XCTest
import RealmSwift

class MultipleUsers: XCTestCase {

    override func tearDown() {
        guard app.currentUser != nil else {
            return
        }
        let expectation = XCTestExpectation(description: "Remove anonymous user from device")
        app.currentUser!.remove { (error) in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }

    func testAddUser() {
        let joeExpectation = XCTestExpectation(description: "joe log in completes")
        let emmaExpectation = XCTestExpectation(description: "emma log in completes")
        // :code-block-start: add-user
        let app = App(id: YOUR_REALM_APP_ID)

        let joeCredentials = Credentials.emailPassword(email: "joe@example.com", password: "passw0rd")
        app.login(credentials: joeCredentials) { (joe, error) in
            DispatchQueue.main.sync {
                guard error == nil else {
                    print("Login failed: \(error!)")
                    // :hide-start:
                    joeExpectation.fulfill()
                    // :hide-end:
                    return
                }

                // The active user is now Joe
                assert(joe == app.currentUser)
            }
        }

        let emmaCredentials = Credentials.emailPassword(email: "emma@example.com", password: "pa55word")
        app.login(credentials: emmaCredentials) { (emma, error) in
            DispatchQueue.main.sync {
                guard error == nil else {
                    print("Login failed: \(error!)")
                    // :hide-start:
                    emmaExpectation.fulfill()
                    // :hide-end:
                    return
                }

                // The active user is now Emma
                assert(emma == app.currentUser)
            }
        }
        // :code-block-end:
        wait(for: [joeExpectation, emmaExpectation], timeout: 10)
    }
    
    func testListUsers() {
        // :code-block-start: list-users
        let app = App(id: YOUR_REALM_APP_ID)
        let users = app.allUsers
        users.forEach({ (key, user) in
            print("User: \(key) \(user)")
        })
        // :code-block-end:
    }
    
    func testSwitchUsers() {
        // :code-block-start: switch-user
        let app = App(id: YOUR_REALM_APP_ID)
        
        // :hide-start:
        XCTAssertNil(app.currentUser)
        // :hide-end:
        // ... log in ...
        // :hide-start:
        func getSomeOtherUser() -> User {
            var result: User? = nil
            let expectation = XCTestExpectation(description: "it logs in")
            app.login(credentials: Credentials.anonymous) { (user, error) in
                result = user!
                user!.logOut { (error) in
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 20)
            return result!
        }
        // :hide-end:
        // Get another user on the device, for example with `app.allUsers` 
        let secondUser: User = getSomeOtherUser()
        
        XCTAssertNotEqual(app.currentUser, secondUser)
        // assert(app.currentUser != secondUser)
        
        // Switch to another user
        //app.switch(to: secondUser)

        // The switch-to user becomes the app.currentUser
        //XCTAssertEqual(app.currentUser, secondUser)
        //assert(app.currentUser == secondUser)
        // :code-block-end:
    }

    func testLinkIdentities() {
        let expectation = XCTestExpectation(description: "Link user completes")

        // :code-block-start: link-identity
        let app = App(id: YOUR_REALM_APP_ID)

        func logInAnonymously() {
            app.login(credentials: Credentials.anonymous) { (user, error) in
                guard error == nil else {
                    print("Failed to log in: \(error!.localizedDescription)")
                    // :hide-start:
                    XCTAssert(false, "Failed to log in: \(error!.localizedDescription)")
                    // :hide-end:
                    return
                }

                // User uses app, then later registers an account
                registerNewAccount(anonymousUser: user!)
            }
        }

        func registerNewAccount(anonymousUser: User) {
            let email = "link@example.com"
            let password = "ganondorf"
            app.emailPasswordAuth.registerUser(email: email, password: password) { (error) in
                guard error == nil else {
                    print("Failed to register new account: \(error!.localizedDescription)")
                    // :hide-start:
                    XCTAssert(false, "Failed to register new account: \(error!.localizedDescription)")
                    // :hide-end:
                    return
                }

                // Successfully created account, now link it
                // with the existing anon user
                link(user: anonymousUser, with: Credentials.emailPassword(email: email, password: password))
            }
        }

        func link(user: User, with credentials: Credentials) {
            user.linkUser(credentials: credentials) { (user, error) in
                guard error == nil else {
                    print("Failed to link user: \(error!.localizedDescription)")
                    // :hide-start:
                    XCTAssert(false, "Failed to link user: \(error!.localizedDescription)")
                    // :hide-end:
                    return
                }

                print("Successfully linked user: \(user!)")

                // :hide-start:
                expectation.fulfill()
                // :hide-end:
            }
        }

        logInAnonymously()
        // :code-block-end:
        wait(for: [expectation], timeout: 10)
    }
}
