
pub const Stack = struct {
    last: *Node,

    pub const SNode = struct {
        curr: *Node,
        next: ?*Node,

        pub fn init(token: *Token) Stack {
            const n = Node.init(token);
            return Stack{
                .curr = &n,
                .next = null,
                .last = &n,
            };
        }

        pub fn push(stack: *Stack, token: *Token) void {
            var node = Node.init(token);

        }
    };
};
