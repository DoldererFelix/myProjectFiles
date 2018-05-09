pragma solidity ^0.4.0;
/**
 * The PlatoonManagement contract adds, tracks and compensates trucks in a platoon.
 */
contract PlatoonManagement {

	struct Truck {
		address addr;
		uint depositAmount;
		uint entryTime;
	}
	
	uint collectedPayments;
	uint nextIndex = 0;
	Truck[] public platoon;
	bool firstRun = true;
	
	constructor () public {}
    
    mapping (address => uint) reputation;
    
    function() payable public {
        joinPlatoon();
    }
	
	function joinPlatoon() public payable returns(bool res) {
	    
	    require (checkDoubleEntry(msg.value));
	    require (checkSufficientDeposit());
	    //For the demonstration, just set the reputation to a valid value
		reputation[msg.sender] = 10;
		/*Query the reputation from somewhere instead of hardcoding it*/
		if (reputation[msg.sender] >= 5){
		    /*joining*/
			address addr = msg.sender;
			uint depositAmount = msg.value;
			uint entryTime = block.timestamp;
			if (firstRun){nextIndex = 10; firstRun=false;}
			if(nextIndex==10){
    			platoon.push(Truck(addr, depositAmount, entryTime));
			} else {
			    platoon[nextIndex] = Truck(addr, depositAmount, entryTime);
			    nextIndex = 10;
			}
		} else {
		    /*not joining*/
			revert();
		}
		return true;
	}
    
	function leavePlatoon() public returns(bool res) {
	    /*Pay according to time spend in the platoon.*/
		for (uint i = 0; i < platoon.length; i++) {
			if(msg.sender == platoon[i].addr){
			    /*first guy leaving is special, he gets the funds of the contract*/
				uint paymentAmount = calculatePayment(i);
				/*Transfer the paymentAmount from truck i to the first truck*/
				platoon[i].depositAmount -= paymentAmount;
				platoon[0].depositAmount += paymentAmount;
				/*Transfer remaining deposit to the address of the leaving truck*/
				goodBey(i);
				return true;
			}
		}
		return false;
	}
	
	function calculatePayment(uint truckNumber) public view returns(uint) {
	    uint timeInPlatoon = (block.timestamp - platoon[truckNumber].entryTime);
	    uint paymentAmount = timeInPlatoon;
	    return paymentAmount;
	}
	
	function checkDoubleEntry(uint _deposit) internal returns(bool) {
	    for(uint i = 0; i < platoon.length; i++) {
	        if (msg.sender == platoon[i].addr) {
	            platoon[i].depositAmount += _deposit;
	            return false;
	        }
	    }
	    return true;
	}
	
	function checkSufficientDeposit() internal view returns(bool) {
	    if(msg.value < .1 * 10 ** 18){
	        return false;
	    }
	    return true;
	}
	
	function checkFunds() public {
	    for (uint i = 0; i < platoon.length; i++){
	        uint remainingBalance = platoon[i].depositAmount - calculatePayment(i);
	        if (remainingBalance < 0.00001 * 10 ** 18) {
	            goodBey(i);
	        }
	    }
	}
	
	function goodBey(uint i) internal {
	    platoon[i].addr.transfer(platoon[i].depositAmount);
		nextIndex = i;
		delete platoon[i];
	}
	
}