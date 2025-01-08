
module admin::week_two {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use std::string::{String};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use std::type_name::{Self, TypeName};
    use sui::balance::{Self, Balance};
    use sui::dynamic_field;
    use std::ascii::{String as AString};
  



    //==============================================================================================
    // Constants
    //==============================================================================================

    //==============================================================================================
    // Error codes
    //==============================================================================================
    //// You already have a Profile
    const EProfileExist: u64 = 1;
    
    //==============================================================================================
    // Structs 
    //==============================================================================================
    public struct State has key{
        id: UID,
        // users: vector<address>,
        //alternative <owner_address, profile_object_address>
        users: Table<address, address>,
    }
    
    public struct Profile has key{
        id: UID,
        name: String,
        description: String,
        folders: vector<address>,
    }

    public struct Folder has key{
        id: UID,
        name: String,
        description: String,
    }

    //==============================================================================================
    // Event Structs 
    //==============================================================================================
    public struct ProfileCreated has copy, drop {
        profile: address,
        owner: address,
    }

    public struct FolderCreated has copy, drop{
        id: ID,
        owner: address
    }

    public struct CoinWrapped has copy, drop{
        folder: address,
        coin_type: AString,
        amount: u64,
        new_balance: u64,
    }

    //==============================================================================================
    // Init  创建一个共享 Stata对象
    //       State对象包含一个 Table存储用户的地址 和 Profile 地址映射
    //==============================================================================================
    fun init(ctx: &mut TxContext) {
        transfer::share_object(State{
            id: object::new(ctx), 
            users: table::new(ctx),
        });
    }

    //==============================================================================================
    // Entry Functions   创建用户 Profile的入口函数 检测用户是否已有 Profile
    //                   创建新的 Profile 对象 并转移给调用者
   //                   在 State 中记录用户地址和 Profile 地址映射
   //                   触发 ProfileCreated 事件
    //==============================================================================================
    public entry fun create_profile(
        name: String, 
        description: String, 
        state: &mut State,
        ctx: &mut TxContext
    ){
        let owner = tx_context::sender(ctx);
        assert!(!table::contains(&state.users, owner), EProfileExist);
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        let new_profile = Profile {
            id: uid,
            name,
            description,
            folders: vector::empty(),
        };
        transfer::transfer(new_profile, owner);
        table::add(&mut state.users, owner, object::id_to_address(&id));
        event::emit(ProfileCreated{
            profile: object::id_to_address(&id),
            owner,
        });
    }
    
    //===========================================================================================
    //   创建文件夹的的入口函数
    //   创建新的Folder对象并转移给调用者
    //   将文件夹地址添加到用户的Profile中
    //   触发FolderCreated事件
    //===========================================================================================
    public entry fun create_folder(
        name: String,
        description: String,
        profile: &mut Profile,
        ctx: &mut TxContext
    ){
        let owner = tx_context::sender(ctx);
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        let new_folder = Folder {
            id: uid,
            name,
            description,
        };
        transfer::transfer(new_folder, owner);
        vector::push_back(&mut profile.folders, object::id_to_address(&id));
        event::emit(FolderCreated{
            id,
            owner
        });
    }

    //=====================================================================================
    //    将代币添加到文件夹的入口函数
    //    支持泛型T表示不同代币类型
    //    如果文件夹中已有该类型代币，则合并余额
    //    如果文件夹中没有该类型代币，则创建新的余额记录
    //    触发CoinWrapped事件
    //===================================================================================== 
    public entry fun add_coin_to_folder<T>(
        folder: &mut Folder,
        coin: Coin<T>,
        _ctx: &mut TxContext
    ){
        let type_name = type_name::get<T>();
        let amount = coin::value(&coin);
        let total;
        if(!dynamic_field::exists_(&folder.id, type_name)){
            dynamic_field::add(&mut folder.id, type_name, coin::into_balance(coin));
            total = amount;
        }else{
            let old_value = dynamic_field::borrow_mut<TypeName, Balance<T>>(&mut folder.id, type_name);
            balance::join(old_value, coin::into_balance(coin));
            total = balance::value(old_value);
        };
        event::emit(CoinWrapped{
            folder: object::uid_to_address(&folder.id),
            coin_type: type_name::into_string(type_name),
            amount,
            new_balance: total,
        })
    }

    //==============================================================================================
    // Getter Functions   检查用户是否已有Profile
    //                    返回Option类型，包含Profile地址或None
    //==============================================================================================
    public fun check_if_has_profile(
        user_wallet_address: address,
        state: &State,
    ): Option<address>{
        if(table::contains(&state.users, user_wallet_address)){
            option::some(*table::borrow(&state.users, user_wallet_address))
        }else{
            option::none()
        }
    }

   //=======================================================================================
   //        获取文件夹中指定类型代币的余额
   //        如果文件夹中没有该类型代币，返回0
    public fun get_balance<T>(
        folder: &Folder
    ): u64{
        if(dynamic_field::exists_(&folder.id, type_name::get<T>())){
            balance::value(dynamic_field::borrow<TypeName, Balance<T>>(&folder.id, type_name::get<T>()))
        }else{
            0
        }   
    }

    //==============================================================================================
    // Helper Functions 
    //==============================================================================================
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
