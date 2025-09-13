module MyModule::MusicArtVoting {
    use aptos_framework::signer;
    use std::vector;
    use aptos_framework::timestamp;

    /// Struct representing a music/art piece for voting
    struct ArtPiece has store, key {
        title: vector<u8>,     // Title of the music/art piece
        artist: address,       // Address of the artist
        vote_count: u64,       // Total votes received
        voters: vector<address>, // List of addresses that voted
        created_at: u64,       // Timestamp when created
    }

    /// Global storage for all art pieces
    struct VotingRegistry has key {
        art_pieces: vector<ArtPiece>,
        total_pieces: u64,
    }

    /// Error codes
    const E_ALREADY_VOTED: u64 = 1;
    const E_VOTING_NOT_INITIALIZED: u64 = 2;
    const E_INVALID_PIECE_INDEX: u64 = 3;

    /// Function 1: Submit a new music/art piece for voting
    public fun submit_art_piece(
        artist: &signer, 
        title: vector<u8>
    ) acquires VotingRegistry {
        let artist_addr = signer::address_of(artist);
        
        // Initialize registry if it doesn't exist
        if (!exists<VotingRegistry>(@MyModule)) {
            let registry = VotingRegistry {
                art_pieces: vector::empty<ArtPiece>(),
                total_pieces: 0,
            };
            move_to(artist, registry);
        };

        let registry = borrow_global_mut<VotingRegistry>(@MyModule);
        
        let new_piece = ArtPiece {
            title,
            artist: artist_addr,
            vote_count: 0,
            voters: vector::empty<address>(),
            created_at: timestamp::now_seconds(),
        };

        vector::push_back(&mut registry.art_pieces, new_piece);
        registry.total_pieces = registry.total_pieces + 1;
    }

    /// Function 2: Vote for a specific art piece by index
    public fun vote_for_art(
        voter: &signer, 
        piece_index: u64
    ) acquires VotingRegistry {
        assert!(exists<VotingRegistry>(@MyModule), E_VOTING_NOT_INITIALIZED);
        
        let voter_addr = signer::address_of(voter);
        let registry = borrow_global_mut<VotingRegistry>(@MyModule);
        
        assert!(piece_index < vector::length(&registry.art_pieces), E_INVALID_PIECE_INDEX);
        
        let art_piece = vector::borrow_mut(&mut registry.art_pieces, piece_index);
        
        // Check if voter has already voted for this piece
        assert!(!vector::contains(&art_piece.voters, &voter_addr), E_ALREADY_VOTED);
        
        // Add vote
        art_piece.vote_count = art_piece.vote_count + 1;
        vector::push_back(&mut art_piece.voters, voter_addr);
    }
}