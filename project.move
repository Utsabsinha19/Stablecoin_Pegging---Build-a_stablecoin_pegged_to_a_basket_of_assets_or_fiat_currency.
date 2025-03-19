module MyModule::StableCoin {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    
    /// Struct representing our stablecoin
    struct StableCoin has key {
        reserve: Coin<AptosCoin>,       // Aptos coins held as reserve
        stable_coins_minted: u64,       // Number of stablecoins in circulation
        peg_ratio: u64,                 // Peg ratio (100 = 1:1 with AptosCoin)
        last_update: u64,               // Last time the peg was updated
    }
    
    /// Error codes
    const E_INSUFFICIENT_RESERVE: u64 = 1;
    const E_ZERO_MINT_AMOUNT: u64 = 2;
    
    /// Initialize the stablecoin with a reserve amount and peg ratio
    public fun initialize_stablecoin(admin: &signer, initial_reserve_amount: u64, initial_peg_ratio: u64) {
        let reserve = coin::withdraw<AptosCoin>(admin, initial_reserve_amount);
        
        let stablecoin = StableCoin {
            reserve,
            stable_coins_minted: 0,
            peg_ratio: initial_peg_ratio,
            last_update: timestamp::now_seconds(),
        };
        
        move_to(admin, stablecoin);
    }
    
    /// Mint stablecoins by depositing AptosCoin as reserve
    public fun mint_stablecoins(
        user: &signer, 
        admin_address: address, 
        deposit_amount: u64
    ) acquires StableCoin {
        assert!(deposit_amount > 0, E_ZERO_MINT_AMOUNT);
        
        let stablecoin = borrow_global_mut<StableCoin>(admin_address);
        let deposit = coin::withdraw<AptosCoin>(user, deposit_amount);
        
        // Calculate how many stablecoins to mint based on the peg ratio
        let mint_amount = (deposit_amount * stablecoin.peg_ratio) / 100;
        
        // Add deposit to reserve
        coin::merge(&mut stablecoin.reserve, deposit);
        
        // Update minted coins
        stablecoin.stable_coins_minted = stablecoin.stable_coins_minted + mint_amount;
        
        // In a real implementation, we would transfer the minted stablecoins to the user
        // For simplicity, we're just tracking the amount minted
    }
}
