// Copyright (C) 2021 Mateus de Lima Oliveira
module kernel.task;
import kernel.paging;
import kernel.idt;
import kernel.heap;
import kernel.common;
import kernel.console;
import kernel.tty;
import kernel.init;
import kernel.tss;
import kernel.isr;

struct Task
{
	int id;                // Process ID.
	uint eip;            // Instruction pointer.
	uint edi, esi, ebp, esp, ebx, edx, ecx, eax;
	PageDirectory *page_directory; // Page directory.
	Task *next;     // The next task in a linked list.
}

extern(C) {
	enum KERNEL_STACK_ADDRESS = 0xB0000000;
	enum KERNEL_STACK_SIZE = 0x4000;

	void SwitchToUserMode(uint ebx, uint ecx, uint edx, uint esi, uint edi, uint ebp, uint eax, uint esp, uint eip);

	// The currently running task.
	static __gshared Task *current_task;

	// The start of the task linked list.
	static __gshared Task *ready_queue;

	// The next available process ID.
	static __gshared uint next_pid = 1;
}

extern(C)
void InitializeTasking(uint stack)
{
	uint initial_esp; // !!!

	initial_esp = stack; // !!!
	char[20] buf;
	printk("Stack start: ");
	itoa(cast(char *) buf, 'x', stack);
	printk(cast(string) buf);
	printk("\n");

    // Rather important stuff happening, no interrupts please!
    DisableInterrupts();

    // Relocate the stack so we know where it is.
    move_stack(stack, cast(void*) KERNEL_STACK_ADDRESS, KERNEL_STACK_SIZE); // !!!
    printk("Stack copied successfully.\n");

    // Initialise the first task (kernel task)
    current_task = ready_queue = cast(Task*)kmalloc(Task.sizeof);
    current_task.id = next_pid++;
    current_task.esp = current_task.ebp = 0;
    current_task.eip = 0;
    current_task.page_directory = currentDirectory;
    current_task.next = null;

    // Reenable interrupts.
    EnableInterrupts();
}

extern(C)
void move_stack(uint old_stack_start, void *new_stack_start, uint size)
{
	__gshared char[20] buf; // !!!
	
	uint i;
  // Allocate some space for the new stack.
  for( i = cast(uint)new_stack_start;
       i < (cast(uint) new_stack_start + size + 0x4000); // !!!
       i += 0x1000)
  {
    // General-purpose stack is in user-mode.
    alloc_frame( getPage(i, 1, currentDirectory), 0 /* User mode */, 1 /* Is writable */ );
  }
  
  // Flush the TLB by reading and writing the page directory address again.
  FlushTLB();
  
  // Old ESP and EBP, read from registers.
  uint old_stack_pointer;
  uint old_base_pointer;
  asm {
		mov old_stack_pointer, ESP;
		mov old_base_pointer, EBP;
	}
	
	uint currentStackSize = size-(old_stack_pointer - old_stack_start); // !!!
	
	// Offset to add to old stack addresses to get a new stack address.
	//uint offset            = cast(uint)new_stack_start - initial_esp;
	//uint offset = size-(old_stack_pointer-initial_esp); // !!!

	// New ESP and EBP.
	// !!!
	//uint new_stack_pointer = old_stack_pointer + offset;
	//uint new_base_pointer  = old_base_pointer  + offset;
	uint new_stack_pointer =
		cast(uint) new_stack_start + (old_stack_pointer - old_stack_start);
	uint new_base_pointer =
		cast(uint) new_stack_start + (old_base_pointer - old_stack_start);
	
	/*printk("XXX\n");
	
	printk("old_stack_start: ");
	itoa(cast(char *) buf, 'x', old_stack_start);
	printk(cast(string) buf);
	printk("\n");*/
	
	/*printk("initial_esp: ");
	itoa(cast(char *) buf, 'x', initial_esp);
	printk(cast(string) buf);
	printk("\n");*/
	
	/*printk("old_stack_pointer: ");
	itoa(cast(char *) buf, 'x', old_stack_pointer);
	printk(cast(string) buf);
	printk("\n");
	
	printk("currentStackSize: ");
	itoa(cast(char *) buf, 'x', currentStackSize);
	printk(cast(string) buf);
	printk("\n");*/
	
	// Copy the stack.
	//memcpy(cast(ubyte*)new_stack_pointer, cast(ubyte*)old_stack_pointer, initial_esp-old_stack_pointer);
	/*memcpy
		(cast(ubyte*)new_stack_pointer,
		cast(ubyte*)old_stack_pointer,
		currentStackSize); // !!!*/
	/*printk("old_stack_pointer[0]: ");
	itoa(cast(char *) buf, 'x', cast(uint) (cast(uint *)old_stack_pointer)[4095]);
	printk(cast(string) buf);
	printk("\n");*/
	memcpy
		(cast(ubyte*)new_stack_start,
		 cast(ubyte*)old_stack_start,
		 size); // !!!
  
  //printk("AAA\n");
  //panic();
  
  // Backtrace through the original stack, copying new values into
  // the new stack.
  // !!!
  /*for(i = cast(uint)new_stack_start; i < cast(uint)new_stack_start+size; i += 4)
  {
	//printk("BBB\n");
    uint tmp = * cast(uint*)i;
    // If the value of tmp is inside the range of the old stack, assume it is a base pointer
    // and remap it. This will unfortunately remap ANY value in this range, whether they are
    // base pointers or not.
    //printk("CCC1\n");
    //panic();
    if ((old_stack_pointer < tmp) && (tmp < initial_esp))
    {
		printk("CCC2\n");
    panic();
      tmp = tmp + offset;
      uint *tmp2 = cast(uint*)i;
      *tmp2 = tmp;
    }
  }*/

	printk("old_stack_pointer: ");
	itoa(cast(char *) buf, 'x', old_stack_pointer);
	printk(cast(string) buf);
	printk("\n");
	
	printk("old_base_pointer: ");
	itoa(cast(char *) buf, 'x', old_base_pointer);
	printk(cast(string) buf);
	printk("\n");
	
	printk("new_stack_pointer: ");
	itoa(cast(char *) buf, 'x', new_stack_pointer);
	printk(cast(string) buf);
	printk("\n");
	
	printk("new_base_pointer: ");
	itoa(cast(char *) buf, 'x', new_base_pointer);
	printk(cast(string) buf);
	printk("\n");
	
	printk("old 2badb002: ");
	itoa(cast(char *) buf, 'x', *(cast(uint *) (old_stack_start + size - 16)));
	printk(cast(string) buf);
	printk("\n");
	
	printk("new 2badb002: ");
	itoa(cast(char *) buf, 'x', *(cast(uint *) (new_stack_start + size - 16)));
	printk(cast(string) buf);
	printk("\n");
	//panic();
  
  asm {
		mov ESP, new_stack_pointer;
		mov EBP, new_base_pointer;
	}
	
	// Flush the TLB by reading and writing the page directory address again.
	FlushTLB();
	
	printk("new_stack_pointer: ");
	itoa(cast(char *) buf, 'x', new_stack_pointer);
	printk(cast(string) buf);
	printk("\n");
	
	printk("new_base_pointer: ");
	itoa(cast(char *) buf, 'x', new_base_pointer);
	printk(cast(string) buf);
	printk("\n");
}

int fork()
{
	char[20] buf; // !!!

    // We are modifying kernel structures, and so cannot
    DisableInterrupts();

    // Take a pointer to this process' task struct for later reference.
    Task *parent_task = cast(Task*)current_task;

    // Clone the address space.
    PageDirectory *directory = clone_directory(currentDirectory);

    // Create a new process.
    Task *new_task = cast(Task*)kmalloc(Task.sizeof);

    new_task.id = next_pid++;
    new_task.esp = new_task.ebp = 0;
    new_task.eip = 0;
    new_task.page_directory = directory;
    new_task.next = null;

    // Add it to the end of the ready queue.
    Task *tmp_task = cast(Task*)ready_queue;
    while (tmp_task.next)
        tmp_task = tmp_task.next;
    tmp_task.next = new_task;

    // This will be the entry point for the new process.
    uint eip = ReadEIP();


	printk("current_task.id: ");
	itoa(cast(char *) buf, 'x', current_task.id);
	printk(cast(string) buf);
	printk("\n");
    // We could be the parent or the child here - check.
    if (current_task == parent_task)
    {
        // We are the parent, so set up the esp/ebp/eip for our child.
        uint esp;
        uint ebp;
        asm {
			mov esp, ESP;
			mov ebp, EBP;
		}
        new_task.esp = esp;
        new_task.ebp = ebp;
        new_task.eip = eip;
        EnableInterrupts();

        return new_task.id;
    }
    else
    {
        // We are the child.
        return 0;
    }

}

int getpid()
{
    return current_task.id;
}

extern(C)
void CreateInitProcess()
{
	DisableInterrupts();
	Task *new_task = NewTask();

	alloc_frame(getPage(0x02000000, 1, currentDirectory), 0 /* User mode */, 1 /* Is writable */ );

	uint size = 2048;
	//void *new_stack_start = kmalloc(size);
	void *new_stack_start = cast(void *) 0x02000000;

	// New user process stack
	new_task.esp = new_task.ebp = cast(uint) new_stack_start + size;
	new_task.eip = cast(uint) &init;
	EnableInterrupts();
}

Task *NewTask()
{
	// Clone the address space.
	PageDirectory *directory = clone_directory(currentDirectory);

	// Create a new process.
	Task *new_task = cast(Task*)kmalloc(Task.sizeof);

	new_task.id = next_pid++;
	new_task.esp = new_task.ebp = 0;
	new_task.eip = 0;
	new_task.page_directory = directory;
	new_task.next = null;
	
	// Add it to the end of the ready queue.
	assert(ready_queue != null);
	Task *tmp_task = cast(Task*)ready_queue;
	while (tmp_task.next != null)
		tmp_task = tmp_task.next;
	tmp_task.next = new_task;

	return new_task;
}

extern(C)
void SwitchTask(ISRRegisters *regs)
{
	char[20] buf; // !!!
	
	if (currentDirectory == null)
		return;
	
	if (current_task == null)
		return;
		
	if (current_task == ready_queue && current_task.next == null)
		return;

	current_task.eip = regs.eip;
	current_task.esp = regs.esp;
	current_task.ebp = regs.ebp;

	current_task.edi = regs.edi;
	current_task.esi = regs.esi;
	current_task.ebx = regs.ebx;
	current_task.edx = regs.edx;
	current_task.ecx = regs.ecx;
	current_task.eax = regs.eax;

	// Get the next task to run.
	current_task = current_task.next;
	// If we fell off the end of the linked list start again at the beginning.
	if (current_task == null)
		current_task = ready_queue;

	uint eip = current_task.eip;
	uint esp = current_task.esp;
	uint ebp = current_task.ebp;

	uint edi = current_task.edi;
	uint esi = current_task.esi;
	//ebp;
	//esp;
	uint ebx = current_task.ebx;
	uint edx = current_task.edx;
	uint ecx = current_task.ecx;
	uint eax = current_task.eax;

	SwitchToUserMode(ebx, ecx, edx, esi, edi, ebp, eax, esp, eip);
}
