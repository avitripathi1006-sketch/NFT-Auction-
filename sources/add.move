module MyModule::NFTAuction {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing an NFT auction
    struct Auction has store, key {
        nft_id: u64,           // NFT identifier being auctioned
        seller: address,       // Original owner of the NFT
        highest_bid: u64,      // Current highest bid amount
        highest_bidder: address, // Address of the highest bidder
        end_time: u64,         // Auction end timestamp
        active: bool,          // Whether auction is still active
    }

    /// Error codes
    const E_AUCTION_NOT_FOUND: u64 = 1;
    const E_AUCTION_ENDED: u64 = 2;
    const E_BID_TOO_LOW: u64 = 3;
    const E_AUCTION_STILL_ACTIVE: u64 = 4;

    /// Function to create a new NFT auction
    public fun create_auction(
        seller: &signer, 
        nft_id: u64, 
        starting_price: u64, 
        duration_seconds: u64
    ) {
        let seller_addr = signer::address_of(seller);
        let current_time = timestamp::now_seconds();
        
        let auction = Auction {
            nft_id,
            seller: seller_addr,
            highest_bid: starting_price,
            highest_bidder: seller_addr,
            end_time: current_time + duration_seconds,
            active: true,
        };
        
        move_to(seller, auction);
    }

    /// Function to place a bid on an NFT auction
    public fun place_bid(
        bidder: &signer, 
        seller_addr: address, 
        bid_amount: u64
    ) acquires Auction {
        let auction = borrow_global_mut<Auction>(seller_addr);
        let current_time = timestamp::now_seconds();
        
        // Check if auction is still active
        assert!(auction.active && current_time < auction.end_time, E_AUCTION_ENDED);
        
        // Check if bid is higher than current highest bid
        assert!(bid_amount > auction.highest_bid, E_BID_TOO_LOW);
        
        // Refund previous highest bidder if not the seller
        if (auction.highest_bidder != auction.seller) {
            let refund = coin::withdraw<AptosCoin>(bidder, auction.highest_bid);
            coin::deposit<AptosCoin>(auction.highest_bidder, refund);
        };
        
        // Process new bid
        let bid_payment = coin::withdraw<AptosCoin>(bidder, bid_amount);
        coin::deposit<AptosCoin>(auction.seller, bid_payment);
        
        // Update auction state
        auction.highest_bid = bid_amount;
        auction.highest_bidder = signer::address_of(bidder);
    }
}