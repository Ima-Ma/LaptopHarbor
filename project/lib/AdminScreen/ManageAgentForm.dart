import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAgentForm extends StatefulWidget {
  const ManageAgentForm({Key? key}) : super(key: key);

  @override
  State<ManageAgentForm> createState() => _ManageAgentFormState();
}

class _ManageAgentFormState extends State<ManageAgentForm> {
  final TextEditingController _agentNameController = TextEditingController();
  final TextEditingController _agentEmailController = TextEditingController();
  final TextEditingController _agentContactController = TextEditingController();

  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editEmailController = TextEditingController();
  final TextEditingController _editContactController = TextEditingController();

  List<Map<String, dynamic>> _agents = [];
  String? _editingAgentId;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    final snapshot = await FirebaseFirestore.instance.collection('Agent').get();
    setState(() {
      _agents = snapshot.docs.map((doc) => {
            'id': doc.id,
            'AgentName': doc['AgentName'],
            'email': doc['email'],
            'contact': doc['contact'],
          }).toList();
    });
  }

  Future<void> _addAgent() async {
    final name = _agentNameController.text.trim();
    final email = _agentEmailController.text.trim();
    final contact = _agentContactController.text.trim();

    if (name.isEmpty || email.isEmpty || contact.isEmpty) return;
    if (contact.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Contact number must be 11 digits")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('Agent').add({
      'AgentName': name,
      'email': email,
      'contact': contact,
    });

    _agentNameController.clear();
    _agentEmailController.clear();
    _agentContactController.clear();
    _fetchAgents();
  }

  Future<void> _updateAgent(String id) async {
    final updatedName = _editNameController.text.trim();
    final updatedEmail = _editEmailController.text.trim();
    final updatedContact = _editContactController.text.trim();

    if (updatedName.isEmpty || updatedEmail.isEmpty || updatedContact.isEmpty) return;
    if (updatedContact.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Contact number must be 11 digits")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('Agent').doc(id).update({
      'AgentName': updatedName,
      'email': updatedEmail,
      'contact': updatedContact,
    });

    _editingAgentId = null;
    _editNameController.clear();
    _editEmailController.clear();
    _editContactController.clear();
    _fetchAgents();
  }

  Future<void> _deleteAgent(String id) async {
    await FirebaseFirestore.instance.collection('Agent').doc(id).delete();
    _fetchAgents();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔷 Agent Form
        Card(
          color: Colors.white.withOpacity(0.1),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Center(
                  child: Text(
                    "Register New Agent ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                buildTextField("Agent Name", _agentNameController),
                const SizedBox(height: 12),
                buildTextField("Agent Email", _agentEmailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                buildTextField("Agent Contact", _agentContactController, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _addAgent,
                    child: Text("Register New Agent"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF539b69),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Existing Agents",
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),

        // 🔁 Agent Cards
        ..._agents.map((agent) {
          final isEditing = _editingAgentId == agent['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ListTile(
              title: isEditing
                  ? Column(
                      children: [
                        buildTextField("Name", _editNameController),
                        const SizedBox(height: 8),
                        buildTextField("Email", _editEmailController),
                        const SizedBox(height: 8),
                        buildTextField("Contact", _editContactController, keyboardType: TextInputType.number),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${agent['AgentName']}", style: TextStyle(color: Colors.white)),
                        Text("Email: ${agent['email']}", style: TextStyle(color: Colors.white)),
                        Text("Contact: ${agent['contact']}", style: TextStyle(color: Colors.white)),
                      ],
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isEditing
                      ? IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => _updateAgent(agent['id']),
                        )
                      : IconButton(
                          icon: Icon(Icons.edit, color:Color(0xFF539b69)),
                          onPressed: () {
                            setState(() => _editingAgentId = agent['id']);
                            _editNameController.text = agent['AgentName'];
                            _editEmailController.text = agent['email'];
                            _editContactController.text = agent['contact'];
                          },
                        ),
                 IconButton(
                icon: const Icon(Icons.delete, color:Color.fromARGB(255, 234, 30, 53)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Color.fromARGB(255, 15, 20, 26),
                      title: const Text("Delete Agent?", style: TextStyle(color: Colors.white)),
                      content: const Text("Are you sure you want to delete this agent?",
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    _deleteAgent(agent['id']);
                  }
                },
              ),

                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.greenAccent),
        ),
      ),
    );
  }
}
