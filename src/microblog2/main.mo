import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time"

actor {
	public type Message = {
        data: Text;
        time: Time.Time;
    };

	public type Microblog = actor {
		follow: shared(Principal) -> async ();
		follows: shared query() -> async [Principal];
		post: shared (Text) -> async ();
		posts: shared query (Time.Time) -> async [Message];
		timeline: shared (Time.Time) -> async [Message];
	};

	stable var followed : List.List<Principal> = List.nil();

	public shared func follow(id: Principal) : async () {
		followed := List.push(id, followed);
	};

	public shared query func follows(): async [Principal] {
		List.toArray(followed);
	};

	stable var messages : List.List<Message> = List.nil();

	public shared func post(text: Text) : async () {
		messages := List.push({data = text; time = Time.now()}, messages);
	};

	public shared query func posts(since: Time.Time) : async [Message] {
		var result : List.List<Message> = List.nil();
        for (msg in Iter.fromList(messages)) {
            if (msg.time > since) {
                result := List.push(msg, result);
            };
        };
        List.toArray(result);
	};

	public shared func timeline(since: Time.Time) : async [Message] {
		var all : List.List<Message> = List.nil();

		for (id in Iter.fromList(followed)) {
			let canister : Microblog = actor(Principal.toText(id));
			let msgs = await canister.posts(since);
			for (msg in Iter.fromArray(msgs)) {
				if (msg.time > since) {
                    all := List.push(msg, all);
                };
			};
		};

		List.toArray(all);
	}
}
