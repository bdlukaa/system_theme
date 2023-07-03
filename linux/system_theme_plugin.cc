#include "include/system_theme/system_theme_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define SYSTEM_THEME_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), system_theme_plugin_get_type(), \
                              SystemThemePlugin))

struct _SystemThemePlugin {
	GObject parent_instance;
	FlPluginRegistrar *registrar;
};

G_DEFINE_TYPE(SystemThemePlugin, system_theme_plugin, g_object_get_type())


static FlValue *get_accent_color(GtkWidget *widget) {
	GdkRGBA accentColor;
	GtkStyleContext *context = gtk_widget_get_style_context(widget);
	gtk_style_context_lookup_color(context, "theme_selected_bg_color", &accentColor);

	FlValue *map = fl_value_new_map();

	fl_value_set_string_take(map, "R", fl_value_new_int((int) (accentColor.red * 255)));
	fl_value_set_string_take(map, "G", fl_value_new_int((int) (accentColor.green * 255)));
	fl_value_set_string_take(map, "B", fl_value_new_int((int) (accentColor.blue * 255)));
	fl_value_set_string_take(map, "A", fl_value_new_int((int) (accentColor.alpha * 255)));

	return map;
}


// Called when a method call is received from Flutter.
static void system_theme_plugin_handle_method_call(
		SystemThemePlugin *self,
		FlMethodCall *method_call) {
	g_autoptr(FlMethodResponse) response = nullptr;

	const gchar *method = fl_method_call_get_name(method_call);

	if (strcmp(method, "SystemTheme.accentColor") == 0) {
		FlView *view = fl_plugin_registrar_get_view(self->registrar);
		FlValue *accentColor = get_accent_color(GTK_WIDGET(view));
		g_autoptr(FlValue) colors = fl_value_new_map();

		fl_value_set_string_take(colors, "accent", accentColor);
		// other colors here...

		response = FL_METHOD_RESPONSE(fl_method_success_response_new(colors));

	} else {
		response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
	}


	fl_method_call_respond(method_call, response, nullptr);
}

static void system_theme_plugin_dispose(GObject *object) {
	G_OBJECT_CLASS(system_theme_plugin_parent_class)->dispose(object);
}

static void system_theme_plugin_class_init(SystemThemePluginClass *klass) {
	G_OBJECT_CLASS(klass)->dispose = system_theme_plugin_dispose;
}

static void system_theme_plugin_init(SystemThemePlugin *self) {}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
						   gpointer user_data) {
	SystemThemePlugin *plugin = SYSTEM_THEME_PLUGIN(user_data);
	system_theme_plugin_handle_method_call(plugin, method_call);
}

void system_theme_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
	SystemThemePlugin *plugin = SYSTEM_THEME_PLUGIN(
			g_object_new(system_theme_plugin_get_type(), nullptr));
	plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

	g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
	g_autoptr(FlMethodChannel) channel =
			fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
								  "system_theme",
								  FL_METHOD_CODEC(codec));
	fl_method_channel_set_method_call_handler(channel, method_call_cb,
											  g_object_ref(plugin),
											  g_object_unref);

	g_object_unref(plugin);
}
